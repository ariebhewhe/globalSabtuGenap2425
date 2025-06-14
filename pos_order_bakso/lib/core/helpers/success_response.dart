class SuccessResponse<T> {
  final String message;
  final T data;

  SuccessResponse({this.message = "Success", required this.data});
}
