import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_event_qna.dart';
import '../../../domain/usecases/ask_question.dart';
import '../../../domain/usecases/upvote_question.dart';
import 'qna_event.dart';
import 'qna_state.dart';

class QnABloc extends Bloc<QnAEvent, QnAState> {
  final GetEventQnA getEventQnA;
  final AskQuestion askQuestion;
  final UpvoteQuestion upvoteQuestion;
  final RemoveUpvote removeUpvote;

  QnABloc({
    required this.getEventQnA,
    required this.askQuestion,
    required this.upvoteQuestion,
    required this.removeUpvote,
  }) : super(QnAInitial()) {
    on<LoadEventQnA>(_onLoadEventQnA);
    on<RefreshEventQnA>(_onRefreshEventQnA);
    on<AskQuestionRequested>(_onAskQuestion);
    on<UpvoteQuestionToggled>(_onUpvoteToggled);
  }

  Future<void> _onLoadEventQnA(
    LoadEventQnA event,
    Emitter<QnAState> emit,
  ) async {
    emit(QnALoading());

    try {
      final result = await getEventQnA(
        GetEventQnAParams(eventId: event.eventId),
      );

      result.fold(
        (failure) {
          print('[QnABloc] Failed to load Q&A: ${failure.toString()}');
          emit(QnAError('Failed to load Q&A: ${failure.toString()}'));
        },
        (questions) {
          print('[QnABloc] Successfully loaded ${questions.length} questions');
          emit(QnALoaded(questions: questions, eventId: event.eventId));
        },
      );
    } catch (e, stackTrace) {
      print('[QnABloc] Exception loading Q&A: $e');
      print('[QnABloc] Stack trace: $stackTrace');
      emit(QnAError('Exception loading Q&A: $e'));
    }
  }

  Future<void> _onRefreshEventQnA(
    RefreshEventQnA event,
    Emitter<QnAState> emit,
  ) async {
    try {
      final result = await getEventQnA(
        GetEventQnAParams(eventId: event.eventId),
      );

      result.fold(
        (failure) {
          print('[QnABloc] Failed to refresh Q&A: ${failure.toString()}');
          // Keep current state, just log the error
        },
        (questions) {
          print(
            '[QnABloc] Successfully refreshed ${questions.length} questions',
          );
          emit(QnALoaded(questions: questions, eventId: event.eventId));
        },
      );
    } catch (e) {
      print('[QnABloc] Exception refreshing Q&A: $e');
    }
  }

  Future<void> _onAskQuestion(
    AskQuestionRequested event,
    Emitter<QnAState> emit,
  ) async {
    print('[QnABloc] Asking question for event ${event.eventId}');

    try {
      final result = await askQuestion(
        AskQuestionParams(eventId: event.eventId, question: event.question),
      );

      await result.fold(
        (failure) async {
          print('[QnABloc] Failed to ask question: ${failure.toString()}');
          emit(QnAError('Failed to ask question: ${failure.toString()}'));
        },
        (newQuestion) async {
          print('[QnABloc] Question asked successfully: ${newQuestion.id}');
          print('[QnABloc] Now refreshing Q&A list...');

          // Immediately reload Q&A list to show new question
          final refreshResult = await getEventQnA(
            GetEventQnAParams(eventId: event.eventId),
          );

          refreshResult.fold(
            (failure) {
              print('[QnABloc] Failed to refresh after ask: $failure');
              emit(QnAError('Failed to refresh Q&A list'));
            },
            (questions) {
              print(
                '[QnABloc] Successfully refreshed with ${questions.length} questions',
              );
              emit(QnALoaded(questions: questions, eventId: event.eventId));
            },
          );
        },
      );
    } catch (e, stackTrace) {
      print('[QnABloc] Exception asking question: $e');
      print('[QnABloc] Stack trace: $stackTrace');
      emit(QnAError('Exception: $e'));
    }
  }

  Future<void> _onUpvoteToggled(
    UpvoteQuestionToggled event,
    Emitter<QnAState> emit,
  ) async {
    if (state is! QnALoaded) return;

    final currentState = state as QnALoaded;

    // Optimistic update - update UI immediately
    final updatedQuestions = currentState.questions.map((question) {
      if (question.id == event.questionId) {
        return question.copyWith(
          isUpvotedByCurrentUser: !event.isCurrentlyUpvoted,
          upvotes: event.isCurrentlyUpvoted
              ? (question.upvotes > 0 ? question.upvotes - 1 : 0)
              : question.upvotes + 1,
        );
      }
      return question;
    }).toList();

    emit(currentState.copyWith(questions: updatedQuestions));

    // Call API in background
    try {
      final result = event.isCurrentlyUpvoted
          ? await removeUpvote(event.questionId)
          : await upvoteQuestion(event.questionId);

      result.fold(
        (failure) {
          print('[QnABloc] Failed to update upvote, reverting: $failure');
          // Revert the optimistic update
          final revertedQuestions = updatedQuestions.map((question) {
            if (question.id == event.questionId) {
              return question.copyWith(
                isUpvotedByCurrentUser: event.isCurrentlyUpvoted,
                upvotes: event.isCurrentlyUpvoted
                    ? question.upvotes + 1
                    : (question.upvotes > 0 ? question.upvotes - 1 : 0),
              );
            }
            return question;
          }).toList();
          emit(currentState.copyWith(questions: revertedQuestions));
        },
        (updatedQuestion) {
          print('[QnABloc] Upvote update successful');
          // Keep the optimistic update
        },
      );
    } catch (e) {
      print('[QnABloc] Exception updating upvote: $e');
    }
  }
}
