String applyTemplate(String template, String packageName) {
  return template.replaceAll('{{package}}', packageName);
}
