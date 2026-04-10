/// Optional [EmailJS](https://www.emailjs.com/) setup — free tier works without Firebase Blaze.
///
/// 1. Create a free account at emailjs.com
/// 2. Add an **Email Service** (e.g. Gmail — uses your Gmail, stays within EmailJS free quota)
/// 3. Create an **Email Template** with variables, e.g. `{{user_email}}`, `{{user_name}}`, `{{message}}`
///    Set “To Email” in the template to `{{user_email}}` so each user receives the mail
/// 4. Copy **Public Key**, **Service ID**, **Template ID** into the fields below
///
/// Keys live in the app (fine for small projects). For production, prefer a backend later.
class EmailJsConfig {
  EmailJsConfig._();

  /// Integration → API keys → **Public Key** (same as `user_id` in REST API)
  static const String publicKey = '0c86W5WNUw4NHwULR';

  static const String privateKey = 'Bl0GLhk8zegDpCxwrBZ43';

  /// Email Services → your service → **Service ID**
  static const String serviceId = 'service_3p4228j';

  /// Email Templates → your template → **Template ID**
  static const String templateId = 'template_po3h84r';

  static bool get isConfigured =>
      publicKey.isNotEmpty && serviceId.isNotEmpty && templateId.isNotEmpty;
}
