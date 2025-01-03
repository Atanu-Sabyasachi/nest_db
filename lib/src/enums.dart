/// Represents the different aggregation operations that can be performed on a collection.
enum AggregateOperation {
  /// Calculates the sum of all numerical values in the specified field.
  ///
  /// If the field contains non-numerical values, they are ignored.
  /// If the field is missing from all documents or contains no numerical values, returns 0.
  sum,

  /// Calculates the average of all numerical values in the specified field.
  ///
  /// If the field contains non-numerical values, they are ignored.
  /// If the field is missing from all documents or contains no numerical values, returns 0.
  average,

  /// Finds the minimum numerical value in the specified field.
  ///
  /// If the field contains non-numerical values, they are ignored.
  /// If the field is missing from all documents or contains no numerical values, returns null.
  min,

  /// Finds the maximum numerical value in the specified field.
  ///
  /// If the field contains non-numerical values, they are ignored.
  /// If the field is missing from all documents or contains no numerical values, returns null.
  max,

  /// Counts the total number of values (including nulls) in the specified field.
  ///
  /// If the field is missing from all documents, returns 0.
  count,

  /// Calculates the median of all numerical values in the specified field.
  ///
  /// The median is the middle value when the values are sorted. If there are an even number of values,
  /// the median is the average of the two middle values.
  /// If the field contains non-numerical values, they are ignored.
  /// If the field is missing from all documents or contains no numerical values, returns null.
  median,

  /// Finds the mode(s) of the values in the specified field.
  ///
  /// The mode is the value that appears most frequently. If there are multiple modes (values with the same highest frequency),
  /// a list containing all modes is returned.
  /// If the field is missing from all documents, returns an empty list.
  mode,

  /// Calculates the range (difference between the maximum and minimum values) of all numerical values in the specified field.
  ///
  /// If the field contains non-numerical values, they are ignored.
  /// If the field is missing from all documents or contains no numerical values, returns null.
  range,

  /// Calculates the variance of all numerical values in the specified field.
  ///
  /// Variance measures how spread out the values are from the mean.
  /// If the field contains non-numerical values, they are ignored.
  /// If the field is missing from all documents or contains fewer than two numerical values, returns 0.
  variance,

  /// Calculates the standard deviation of all numerical values in the specified field.
  ///
  /// Standard deviation is the square root of the variance and provides a measure of the typical deviation of values from the mean.
  /// If the field contains non-numerical values, they are ignored.
  /// If the field is missing from all documents or contains fewer than two numerical values, returns 0.
  stddev,
}
