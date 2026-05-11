class PriceFormatter {
  static String format(double price, {int precision = 1}) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(precision)}\u0645';
    }
    if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}\u0643';
    }
    return price.toStringAsFixed(0);
  }
}
