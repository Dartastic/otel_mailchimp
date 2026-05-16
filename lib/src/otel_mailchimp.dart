// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_mailchimp_suppression.dart';

const _tracerName = 'dartastic_otel_libs_mailchimp';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class MailchimpResult {
  const MailchimpResult({
    this.itemCount,
    this.totalItems,
    this.audienceId,
    this.campaignType,
    this.campaignStatus,
    this.contactStatus,
    this.contactRating,
    this.dataCenter,
    this.tier,
    this.requestId,
    this.statusCode,
  });

  /// `*.length` for collection responses.
  final int? itemCount;

  /// `total_items` from collection responses.
  final int? totalItems;

  /// `list_id` (Mailchimp Marketing's "audience" id).
  final String? audienceId;

  /// `regular` / `plaintext` / `absplit` / `rss` / `automation` /
  /// `variate`.
  final String? campaignType;

  /// `save` / `paused` / `schedule` / `sending` / `sent` / `canceled`
  /// / `archived`.
  final String? campaignStatus;

  /// `subscribed` / `unsubscribed` / `cleaned` / `pending` /
  /// `transactional` / `archived` — Mailchimp bills per Active Contact.
  final String? contactStatus;

  /// Member rating 1-5 (engagement score).
  final int? contactRating;

  /// `us1` / `us10` / `us20` / `de1` etc. — the API hostname shard.
  final String? dataCenter;

  /// `free` / `essentials` / `standard` / `premium`.
  final String? tier;

  /// `X-Request-Id`.
  final String? requestId;

  final int? statusCode;
}

class MailchimpCallResult<T> {
  const MailchimpCallResult({required this.value, this.result});
  final T value;
  final MailchimpResult? result;
}

/// Wraps a Mailchimp Marketing API call in a CLIENT span. [operation]
/// is one of `lists.list`, `lists.get`, `lists.add_member`,
/// `lists.update_member`, `lists.batch_add_or_update`,
/// `lists.members.tags`, `campaigns.list`, `campaigns.get`,
/// `campaigns.create`, `campaigns.send`, `campaigns.schedule`,
/// `automations.list`, `automations.start`, `reports.list`,
/// `reports.get`, `ecommerce.stores.list`, `ecommerce.orders.create`,
/// `tags.list`, `templates.list`, `webhooks.create`, `account.get`.
Future<T> tracedMailchimp<T>({
  required String operation,
  required Future<MailchimpCallResult<T>> Function() invoke,
  String? dataCenter,
}) async {
  if (mailchimpInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'mailchimp',
    'rpc.method': operation,
    'mailchimp.operation': operation,
  };
  if (dataCenter != null) m['mailchimp.data_center'] = dataCenter;

  final span = _tracer().startSpan(
    'mailchimp $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.itemCount != null) {
        extras.add(OTel.attributeInt(
          'mailchimp.item_count',
          r.result!.itemCount!,
        ));
      }
      if (r.result!.totalItems != null) {
        extras.add(OTel.attributeInt(
          'mailchimp.total_items',
          r.result!.totalItems!,
        ));
      }
      if (r.result!.audienceId != null) {
        extras.add(OTel.attributeString(
          'mailchimp.audience.id',
          r.result!.audienceId!,
        ));
      }
      if (r.result!.campaignType != null) {
        extras.add(OTel.attributeString(
          'mailchimp.campaign.type',
          r.result!.campaignType!,
        ));
      }
      if (r.result!.campaignStatus != null) {
        extras.add(OTel.attributeString(
          'mailchimp.campaign.status',
          r.result!.campaignStatus!,
        ));
      }
      if (r.result!.contactStatus != null) {
        extras.add(OTel.attributeString(
          'mailchimp.contact.status',
          r.result!.contactStatus!,
        ));
      }
      if (r.result!.contactRating != null) {
        extras.add(OTel.attributeInt(
          'mailchimp.contact.rating',
          r.result!.contactRating!,
        ));
      }
      if (r.result!.dataCenter != null) {
        extras.add(OTel.attributeString(
          'mailchimp.data_center',
          r.result!.dataCenter!,
        ));
      }
      if (r.result!.tier != null) {
        extras.add(OTel.attributeString(
          'mailchimp.tier',
          r.result!.tier!,
        ));
      }
      if (r.result!.requestId != null) {
        extras.add(OTel.attributeString(
          'mailchimp.request.id',
          r.result!.requestId!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Mailchimp HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
