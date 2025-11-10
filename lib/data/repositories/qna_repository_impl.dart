import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/qna.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/qna_repository.dart';
import '../datasources/qna_remote_datasource.dart';

class QnARepositoryImpl implements QnARepository {
  final QnARemoteDataSource remoteDataSource;

  QnARepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<QnA>>> getEventQnA(String eventId) async {
    try {
      print('[QnARepository] Fetching Q&A for event $eventId...');
      final qnaList = await remoteDataSource.getEventQnA(eventId);
      print('[QnARepository] Successfully fetched ${qnaList.length} questions');
      return Right(qnaList);
    } on Failure catch (e) {
      print('[QnARepository] Failure: $e');
      return Left(e);
    } catch (e) {
      print('[QnARepository] Unexpected error: $e');
      return Left(ServerFailure('Failed to get Q&A: $e'));
    }
  }

  @override
  Future<Either<Failure, QnA>> askQuestion(String eventId, String question) async {
    try {
      print('[QnARepository] Asking question for event $eventId...');
      final qna = await remoteDataSource.askQuestion(eventId, question);
      print('[QnARepository] Question asked successfully');
      return Right(qna);
    } on Failure catch (e) {
      print('[QnARepository] Failure: $e');
      return Left(e);
    } catch (e) {
      print('[QnARepository] Unexpected error: $e');
      return Left(ServerFailure('Failed to ask question: $e'));
    }
  }

  @override
  Future<Either<Failure, QnA>> answerQuestion(String questionId, String answer) async {
    try {
      print('[QnARepository] Answering question $questionId...');
      final qna = await remoteDataSource.answerQuestion(questionId, answer);
      print('[QnARepository] Question answered successfully');
      return Right(qna);
    } on Failure catch (e) {
      print('[QnARepository] Failure: $e');
      return Left(e);
    } catch (e) {
      print('[QnARepository] Unexpected error: $e');
      return Left(ServerFailure('Failed to answer question: $e'));
    }
  }

  @override
  Future<Either<Failure, QnA>> upvoteQuestion(String questionId) async {
    try {
      print('[QnARepository] Upvoting question $questionId...');
      await remoteDataSource.upvoteQuestion(questionId);
      print('[QnARepository] Upvote successful');

      // Return a placeholder QnA - the bloc will handle optimistic update
      return Right(QnA(
        id: questionId,
        eventId: '',
        question: '',
        askedBy: User(
          id: '', email: '', name: '',
          createdAt: DateTime.now(),
          settings: const UserSettings(),
          stats: const UserStats(),
          privacy: const UserPrivacy(),
        ),
        askedAt: DateTime.now(),
        upvotes: 0,
        isUpvotedByCurrentUser: true,
      ));
    } on Failure catch (e) {
      print('[QnARepository] Failure: $e');
      return Left(e);
    } catch (e) {
      print('[QnARepository] Unexpected error: $e');
      return Left(ServerFailure('Failed to upvote question: $e'));
    }
  }

  @override
  Future<Either<Failure, QnA>> removeUpvote(String questionId) async {
    try {
      print('[QnARepository] Removing upvote from question $questionId...');
      await remoteDataSource.removeUpvote(questionId);
      print('[QnARepository] Remove upvote successful');

      // Return a placeholder QnA - the bloc will handle optimistic update
      return Right(QnA(
        id: questionId,
        eventId: '',
        question: '',
        askedBy: User(
          id: '', email: '', name: '',
          createdAt: DateTime.now(),
          settings: const UserSettings(),
          stats: const UserStats(),
          privacy: const UserPrivacy(),
        ),
        askedAt: DateTime.now(),
        upvotes: 0,
        isUpvotedByCurrentUser: false,
      ));
    } on Failure catch (e) {
      print('[QnARepository] Failure: $e');
      return Left(e);
    } catch (e) {
      print('[QnARepository] Unexpected error: $e');
      return Left(ServerFailure('Failed to remove upvote: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteQuestion(String questionId) async {
    try {
      print('[QnARepository] Deleting question $questionId...');
      await remoteDataSource.deleteQuestion(questionId);
      print('[QnARepository] Question deleted successfully');
      return const Right(null);
    } on Failure catch (e) {
      print('[QnARepository] Failure: $e');
      return Left(e);
    } catch (e) {
      print('[QnARepository] Unexpected error: $e');
      return Left(ServerFailure('Failed to delete question: $e'));
    }
  }
}
