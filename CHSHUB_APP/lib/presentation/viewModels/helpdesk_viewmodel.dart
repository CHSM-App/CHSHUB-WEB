import 'package:society_app/core/network/error_message_mapper.dart';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:society_app/domain/models/all_spinner.dart';
import 'package:society_app/domain/usecase/helpdesk_usecase.dart';
import 'package:flutter/foundation.dart';
import '../../domain/models/helpdesk.dart';
import '../../domain/models/helpdesk_comment.dart';

@immutable
class HelpdeskRequestState {
  final AsyncValue<List<HelpdeskRequest>> requestList;
  final AsyncValue<List<HelpdeskRequest>> requestListById;
  final AsyncValue<List<HelpdeskComment>> commentList;
  final AsyncValue<List<HelpdeskRequest>> complaintDetail;
  final AsyncValue<List<HelpdeskComment>> complaintComments;
  final Map<String, dynamic>? data;
  final bool isLoading;
  final String? error;
  final AsyncValue<List<AllSpinner>> allComplainTypes;

  // final AsyncValue<int?> insertComment;

  const HelpdeskRequestState({
    this.requestList = const AsyncValue.loading(),
    this.requestListById = const AsyncValue.loading(),
    this.commentList = const AsyncValue.loading(),
    this.complaintDetail = const AsyncValue.loading(),
    this.complaintComments = const AsyncValue.loading(),
    this.isLoading = false,
    this.error,
    this.data,
    this.allComplainTypes = const AsyncValue.loading(),
    // this.insertComment = const AsyncValue.loading(),
  });

  HelpdeskRequestState copyWith({
    AsyncValue<List<HelpdeskRequest>>? requestList,
    AsyncValue<List<HelpdeskRequest>>? requestListById,
    AsyncValue<List<HelpdeskComment>>? commentList,
    AsyncValue<List<HelpdeskRequest>>? complaintDetail,
    AsyncValue<List<HelpdeskComment>>? complaintComments,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? data,
    AsyncValue<List<AllSpinner>>? allComplainTypes,
    // AsyncValue<int?>? insertComment,
  }) {
    return HelpdeskRequestState(
      requestList: requestList ?? this.requestList,
      requestListById: requestListById ?? this.requestListById,
      commentList: commentList ?? this.commentList,
      complaintDetail: complaintDetail ?? this.complaintDetail,
      complaintComments: complaintComments ?? this.complaintComments,
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      allComplainTypes: allComplainTypes ?? this.allComplainTypes,
      // insertComment: insertComment ?? this.insertComment,
    );
  }
}

class HelpdeskViewModel extends StateNotifier<HelpdeskRequestState> {
  final HelpdeskUsecase useCases;

  HelpdeskViewModel(this.useCases) : super(const HelpdeskRequestState());

  // 🟢 Get all helpdesk requests
  Future<void> getHelpdeskList(String societyID,int ownerID) async {
    state = state.copyWith(requestList: const AsyncValue.loading());
    try {
      final result = await useCases.getHelpdeskList(societyID,ownerID);
      state = state.copyWith(requestList: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(requestList: AsyncValue.error(e, st));
    }
  }

  // 🟢 Get helpdesk request by ID
  Future<void> getRequestById(int id) async {
    state = state.copyWith(requestListById: const AsyncValue.loading());
    try {
      final result = await useCases.getRequestById(id);
      state = state.copyWith(requestListById: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(requestListById: AsyncValue.error(e, st));
    }
  }

  // 🟢 Get comments for a request
  Future<void> getComments(int id) async {
    state = state.copyWith(commentList: const AsyncValue.loading());
    try {
      final result = await useCases.getComments(id);
      state = state.copyWith(commentList: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(commentList: AsyncValue.error(e, st));
    }
  }

  // ✅ Insert helpdesk (not altering state object, just returning result)
   Future<void> insertHelpdesk(HelpdeskRequest helpDesk) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await useCases.insertHelpdesk(helpDesk);
      state = state.copyWith(isLoading: false, data: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorMessageMapper.map(e));
    }
  }

  // ✅ Insert comment (not altering state object, just returning result)
  Future<void> insertComments(HelpdeskComment comment) async {
    try {
      final result = await useCases.insertComments(comment);
      state = state.copyWith(isLoading: false, data: result);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorMessageMapper.map(e));
    }
  }

  Future<void> getHelpdeskListByHelpdeskID(int helpDeskID) async {
    state = state.copyWith(complaintDetail: const AsyncValue.loading());
    try {
      final result = await useCases.getHelpdeskListByHelpdeskID(helpDeskID);
      state = state.copyWith(complaintDetail: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(complaintDetail: AsyncValue.error(e, st));
    }
  }

  Future<void> getHelpdeskComments(int helpDeskID) async {
    state = state.copyWith(complaintComments: const AsyncValue.loading());
    try {
      final result = await useCases.getHelpdeskComments(helpDeskID);
      state = state.copyWith(complaintComments: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(complaintComments: AsyncValue.error(e, st));
    }
  }

  // 🟢 Update request status (not altering state object, just returning result)
  Future<dynamic> updateRequest(
    int status,
    int commentID,
    int helpDeskID,
  ) async {
    try {
      final result = await useCases.updateRequest(
        status,
        commentID,
        helpDeskID,
      );
      state = state.copyWith(isLoading: false, data: result);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorMessageMapper.map(e));
    }
  }

  // 🟢 Get all complaint types
  Future<void> getAllComplainTypes() async {
    state = state.copyWith(allComplainTypes: const AsyncValue.loading());
    try {
      final result = await useCases.getAllComplainTypes();
      state = state.copyWith(allComplainTypes: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(allComplainTypes: AsyncValue.error(e, st));
    }
  }

   Future<void> getComplaintType() async {
    state = state.copyWith(allComplainTypes: const AsyncValue.loading());
    try {
      final result = await useCases.getComplaintType();
      state = state.copyWith(allComplainTypes: AsyncValue.data(result));
    } catch (e, st) {
      state = state.copyWith(allComplainTypes: AsyncValue.error(e, st));
    }
  }
  

  // 🟢 Add helpdesk images (not altering state object, just returning result )
  Future<void> addHelpdeskImages(File image,String helpdeskID) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await useCases.addHelpdeskImages(image, helpdeskID);
      state = state.copyWith(isLoading: false, data: result);
      // return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorMessageMapper.map(e));
    }
  }

  //  Future<void> markAsResolved(HelpdeskRequest complaint) async {
  //   try {
  //     await useCases.updateComplaintStatus(complaint.helpdeskId); // Call your API
  //     final updatedList = state.requestList.value!.map((c) {
  //       return c.helpdeskId == complaint.helpdeskId
  //           ? c.copyWith(status: 'RESOLVED')
  //           : c;
  //     }).toList();
  //     state = state.copyWith(requestList: AsyncValue.data(updatedList));
  //   } catch (_) {}
  // }
}
