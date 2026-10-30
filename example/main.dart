// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_mailchimp/otel_mailchimp.dart';

/// Traces Mailchimp Marketing calls with OpenTelemetry.
///
/// `otel_mailchimp` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Mailchimp Marketing call in
/// [tracedMailchimp]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'mailchimp-example');

  // Wraps a Mailchimp Marketing API call in a CLIENT span.
  final mailchimpId = await tracedMailchimp<String>(
    operation: 'campaigns.create',
    dataCenter: 'example',
    invoke: () async {
      // Make the Mailchimp Marketing call here, then report what it returned.
      const id = 'mailchimp_8f3a2c';
      return const MailchimpCallResult(
          value: id,
          result: MailchimpResult(
              itemCount: 3,
              totalItems: 120,
              audienceId: 'list_id',
              campaignType: 'regular',
              campaignStatus: 'save',
              contactStatus: 'subscribed',
              contactRating: 1,
              dataCenter: 'us1',
              tier: 'free',
              requestId: 'request_8f3a2c',
              statusCode: 201));
    },
  );
  OTelLog.info('tracedMailchimp campaigns.create returned $mailchimpId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutMailchimpInstrumentationAsync.
  await runWithoutMailchimpInstrumentationAsync(
    () => tracedMailchimp<String>(
      operation: 'campaigns.create',
      dataCenter: 'example',
      invoke: () async {
        const id = 'mailchimp_8f3a2c';
        return const MailchimpCallResult(
            value: id,
            result: MailchimpResult(
                itemCount: 3,
                totalItems: 120,
                audienceId: 'list_id',
                campaignType: 'regular',
                campaignStatus: 'save',
                contactStatus: 'subscribed',
                contactRating: 1,
                dataCenter: 'us1',
                tier: 'free',
                requestId: 'request_8f3a2c',
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
