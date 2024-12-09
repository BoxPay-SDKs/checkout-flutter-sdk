class PaymentResultObject {
  String? status;
  String? token;

  PaymentResultObject(String statusFetched, String tokenFetched) {
    status = statusFetched;
    token = tokenFetched;
  }
}
