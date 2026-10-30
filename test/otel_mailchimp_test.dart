// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_mailchimp/otel_mailchimp.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_mailchimp-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('campaigns.send records audience + type + dc', () async {
    await tracedMailchimp<String>(
      operation: 'campaigns.send',
      dataCenter: 'us20',
      invoke: () async => const MailchimpCallResult(
        value: 'ok',
        result: MailchimpResult(
          audienceId: 'a1b2c3',
          campaignType: 'regular',
          campaignStatus: 'sending',
          dataCenter: 'us20',
          tier: 'standard',
          statusCode: 204,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('mailchimp campaigns.send')!);
    expect(a['mailchimp.data_center'], 'us20');
    expect(a['mailchimp.audience.id'], 'a1b2c3');
    expect(a['mailchimp.campaign.type'], 'regular');
    expect(a['mailchimp.campaign.status'], 'sending');
    expect(a['mailchimp.tier'], 'standard');
  });

  test('lists.add_member records contact status + rating', () async {
    await tracedMailchimp<String>(
      operation: 'lists.add_member',
      invoke: () async => const MailchimpCallResult(
        value: 'ok',
        result: MailchimpResult(
          contactStatus: 'subscribed',
          contactRating: 4,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('mailchimp lists.add_member')!);
    expect(a['mailchimp.contact.status'], 'subscribed');
    expect(a['mailchimp.contact.rating'], 4);
  });

  test('suppression skips spans', () async {
    await runWithoutMailchimpInstrumentationAsync(() async {
      await tracedMailchimp<String>(
        operation: 'lists.list',
        invoke: () async => const MailchimpCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('mailchimp '), isEmpty);
  });
}
