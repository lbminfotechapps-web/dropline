import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/company_admin_entity.dart';
import '../../domain/usecase/get_pending_invitations_usecase.dart';

class FetchPendingInvitations {
  final String loginUserId, projectId;
  const FetchPendingInvitations({
    required this.loginUserId,
    required this.projectId,
  });
}

class PendingInvitationsState {
  final bool loading;
  final List<CompanyAdminEntity> invitations;
  final String? error;
  const PendingInvitationsState({
    this.loading = false,
    this.invitations = const [],
    this.error,
  });
}

class PendingInvitationsBloc
    extends Bloc<FetchPendingInvitations, PendingInvitationsState> {
  PendingInvitationsBloc(GetPendingInvitationsUsecase getPending)
    : super(const PendingInvitationsState()) {
    on<FetchPendingInvitations>((event, emit) async {
      emit(const PendingInvitationsState(loading: true));
      try {
        final invitations = await getPending(
          loginUserId: event.loginUserId,
          projectId: event.projectId,
        );
        emit(PendingInvitationsState(invitations: invitations));
      } catch (error) {
        emit(
          PendingInvitationsState(
            error: error.toString().replaceFirst('Exception: ', ''),
          ),
        );
      }
    });
  }
}
