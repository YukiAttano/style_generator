import "package:analyzer/dart/constant/value.dart";

extension DartObjectExtension on DartObject {
  Object? toValue() {
    return toStringValue() ??
        toDoubleValue() ??
        toIntValue() ??
        toBoolValue() ??
        toMapValue()?.map((key, value) => MapEntry(key?.toValue(), value?.toValue())) ??
        toSetValue()?.map((e) => e.toValue()).toList() ??
        toListValue()?.map((e) => e.toValue()).toList() ??
        toFunctionValue() ??
        toRecordValue() ??
        toSymbolValue() ??
        toTypeValue();
  }
}
