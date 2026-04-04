<?php
  $rawData = file_get_contents("php://input");
  $data = json_decode($rawData, true);

  $headers = getallheaders();

  $received_api_key = '';

  if (isset($headers['mh-piprapay-api-key'])) {
      $received_api_key = $headers['mh-piprapay-api-key'];
  } elseif (isset($headers['Mh-Piprapay-Api-Key'])) {
      $received_api_key = $headers['Mh-Piprapay-Api-Key'];
  } elseif (isset($_SERVER['HTTP_MH_PIPRAPAY_API_KEY'])) {
      $received_api_key = $_SERVER['HTTP_MH_PIPRAPAY_API_KEY']; // fallback if needed
  }

  if ($received_api_key !== "YOUR_API") {
      status_header(401);
      echo json_encode(["status" => false, "message" => "Unauthorized request."]);
      exit;
  }

  $pp_id = $data['pp_id'] ?? '';
  $customer_name = $data['customer_name'] ?? '';
  $customer_email_mobile = $data['customer_email_mobile'] ?? '';
  $payment_method = $data['payment_method'] ?? '';
  $amount = $data['amount'] ?? 0;
  $fee = $data['fee'] ?? 0;
  $refund_amount = $data['refund_amount'] ?? 0;
  $total = $data['total'] ?? 0;
  $currency = $data['currency'] ?? '';
  $status = $data['status'] ?? '';
  $date = $data['date'] ?? '';

  $metadata = $data['metadata'] ?? [];

  http_response_code(200);
  echo json_encode(['status' => true, 'message' => 'Webhook received']);
