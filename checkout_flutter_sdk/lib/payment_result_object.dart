class PaymentResultObject {
  String? result;
  String? transactionId;

  PaymentResultObject(String resultFetched, String id) {
    result = resultFetched;
    transactionId = id;
  }
}
