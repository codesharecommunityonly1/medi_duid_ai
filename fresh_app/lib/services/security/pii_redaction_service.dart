class PIIRedactionService {
  static String redactPII(String text) {
    String redacted = text;
    
    // Redact phone numbers
    final phoneRegex = RegExp(r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b');
    redacted = redacted.replaceAll(phoneRegex, '[PHONE_REDACTED]');
    
    // Redact SSN
    final ssnRegex = RegExp(r'\b\d{3}[-]?\d{2}[-]?\d{4}\b');
    redacted = redacted.replaceAll(ssnRegex, '[SSN_REDACTED]');
    
    // Redact email addresses
    final emailRegex = RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b');
    redacted = redacted.replaceAll(emailRegex, '[EMAIL_REDACTED]');
    
    // Redact addresses (simple pattern)
    final addressRegex = RegExp(r'\b\d+\s+[A-Za-z]+\s+(Street|St|Avenue|Ave|Road|Rd|Boulevard|Blvd|Drive|Dr|Lane|Ln|Court|Ct)\b', caseSensitive: false);
    redacted = redacted.replaceAll(addressRegex, '[ADDRESS_REDACTED]');
    
    // Redact names (simple pattern - looks for capitalized words that might be names)
    // This is a conservative approach - we don't want to over-redact
    final namePatterns = [
      RegExp(r'\bmy name is [A-Z][a-z]+\b', caseSensitive: false),
      RegExp(r'\bi am [A-Z][a-z]+\b', caseSensitive: false),
      RegExp(r'\bthis is [A-Z][a-z]+\b', caseSensitive: false),
    ];
    
    for (var pattern in namePatterns) {
      redacted = redacted.replaceAll(pattern, '[NAME_REDACTED]');
    }
    
    // Redact dates of birth (simple pattern)
    final dobRegex = RegExp(r'\b(dob|date of birth)[:\s]+\d{1,2}[/\-]\d{1,2}[/\-]\d{2,4}\b', caseSensitive: false);
    redacted = redacted.replaceAll(dobRegex, '[DOB_REDACTED]');
    
    // Redact medical record numbers
    final mrnRegex = RegExp(r'\b(mrn|medical record|patient id)[:\s#]*\d+\b', caseSensitive: false);
    redacted = redacted.replaceAll(mrnRegex, '[MRN_REDACTED]');
    
    // Redact insurance IDs
    final insuranceRegex = RegExp(r'\b(insurance|id)[:\s#]*[A-Z0-9]{6,}\b', caseSensitive: false);
    redacted = redacted.replaceAll(insuranceRegex, '[INSURANCE_REDACTED]');
    
    return redacted;
  }
  
  static String getRedactionReport(String originalText) {
    final redacted = redactPII(originalText);
    final issues = <String>[];
    
    if (redacted.contains('[PHONE_REDACTED]')) issues.add('Phone number detected and redacted');
    if (redacted.contains('[EMAIL_REDACTED]')) issues.add('Email address detected and redacted');
    if (redacted.contains('[SSN_REDACTED]')) issues.add('SSN detected and redacted');
    if (redacted.contains('[ADDRESS_REDACTED]')) issues.add('Address detected and redacted');
    if (redacted.contains('[NAME_REDACTED]')) issues.add('Potential name detected and redacted');
    if (redacted.contains('[DOB_REDACTED]')) issues.add('Date of birth detected and redacted');
    if (redacted.contains('[MRN_REDACTED]')) issues.add('Medical record number detected and redacted');
    if (redacted.contains('[INSURANCE_REDACTED]')) issues.add('Insurance ID detected and redacted');
    
    return issues.isEmpty 
      ? 'No PII/PHI detected'
      : 'PII Redaction Report:\n${issues.join('\n')}';
  }
  
  static bool hasPII(String text) {
    final patterns = [
      RegExp(r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b'),
      RegExp(r'\b\d{3}[-]?\d{2}[-]?\d{4}\b'),
      RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'),
    ];
    
    for (var pattern in patterns) {
      if (pattern.hasMatch(text)) return true;
    }
    return false;
  }
}
