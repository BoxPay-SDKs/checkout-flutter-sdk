class PaymentResultObject {
  String? status;
  String? transactionId;

  PaymentResultObject(String statusFetched, String tokenFetched) {
    status = statusFetched;
    transactionId = tokenFetched;
  }
}
