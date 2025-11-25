import 'package:xapptor_logic/random/random_number_with_range.dart';

enum SlideshowViewOrientation {
  portrait,
  landscape,
  square_or_similar,
}

List<List<Map<String, dynamic>>> get_slideshow_matrix({
  required double screen_height,
  required double screen_width,
  required bool portrait,
  required int number_of_columns,
}) {
  List<List<Map<String, dynamic>>> matrix = [];

  int last_number_of_views = 0;

  // For each column
  for (var column_index = 0; column_index < number_of_columns; column_index++) {
    //
    int random_number_of_views = random_number_with_range(1, 3);

    // Avoid same number of views in adjacent columns
    if (random_number_of_views == last_number_of_views) {
      if (random_number_of_views > 1) {
        random_number_of_views -= 1;
      } else {
        random_number_of_views += 1;
      }
    }
    // <-- END

    // Adjustments for portrait mode to avoid columns with only one view, or both columns with 2 views
    if (portrait) {
      if (random_number_of_views == 1) {
        random_number_of_views = 2;

        if (random_number_of_views == last_number_of_views) {
          random_number_of_views = 3;
        }
      }
    }
    // <-- END

    // Save last number of views until before last iteration
    if (column_index < number_of_columns - 1) {
      last_number_of_views = random_number_of_views;
    }
    // <-- END

    matrix.add(
      List.filled(random_number_of_views, {}),
    );

    // For each view in the column
    for (var view_index = 0; view_index < random_number_of_views; view_index++) {
      //
      int random_for_flex = random_number_with_range(1, 2);

      if (portrait) {
        //
        if (matrix.length > 1 && column_index > 0) {
          //
          // Avoid same flex pattern in adjacent columns when in portrait mode and having 2 columns with 2 views each
          //
          if (random_number_of_views == 2 && last_number_of_views == 2) {
            //
            if (matrix[column_index - 1][0] == matrix[column_index][0]) {
              //
              if (matrix[column_index - 1][1] == matrix[column_index][1]) {
                //
                if (random_for_flex > 1) {
                  random_for_flex -= 1;
                } else {
                  random_for_flex += 1;
                }
              }
            }
          }
        }
      }
      matrix[column_index][view_index] = {
        'flex': random_for_flex,
        'orientation': SlideshowViewOrientation.portrait,
      };
    }
  }

  // Re-calculate orientation for each view in the matrix
  matrix = _recalculate_matrix_orientation(
    screen_height: screen_height,
    screen_width: screen_width,
    matrix: matrix,
  );
  // <- END

  // Final check to avoid when in portrait mode having only portrait views
  if (portrait) {
    bool all_portrait = true;

    for (var column in matrix) {
      for (var view in column) {
        if (view['orientation'] != SlideshowViewOrientation.portrait) {
          all_portrait = false;
          break;
        }
      }
      if (!all_portrait) {
        break;
      }
    }

    // If all portrait, adjust first and last view flex to create landscape or square views
    if (all_portrait) {
      matrix.first.first['flex'] += 2;
      matrix.last.last['flex'] += 2;

      // Re-calculate orientation for each view in the matrix
      matrix = _recalculate_matrix_orientation(
        screen_height: screen_height,
        screen_width: screen_width,
        matrix: matrix,
      );
      // <- END
    }
  }
  // <- END

  // Calculate view heights
  for (int column_index = 0; column_index < matrix.length; column_index++) {
    var column = matrix[column_index];
    int total_flex_of_this_column = column.fold(0, (sum, item) => sum + item['flex'] as int);

    for (int view_index = 0; view_index < column.length; view_index++) {
      var view = column[view_index];

      double current_view_height = ((screen_height / total_flex_of_this_column) * view['flex']);

      matrix[column_index][view_index]['height'] = current_view_height;
    }
  }
  // <- END

  matrix = _calculate_possible_positions_for_videos(
    matrix: matrix,
  );

  return matrix;
}

// Re-calculate orientation for each view in the matrix
List<List<Map<String, dynamic>>> _recalculate_matrix_orientation({
  required double screen_height,
  required double screen_width,
  required List<List<Map<String, dynamic>>> matrix,
}) {
  for (int column_index = 0; column_index < matrix.length; column_index++) {
    var column = matrix[column_index];
    int total_flex_of_this_column = column.fold(0, (sum, item) => sum + item['flex'] as int);

    for (int view_index = 0; view_index < column.length; view_index++) {
      var view = column[view_index];

      double current_view_height = (screen_height / total_flex_of_this_column) * view['flex'];

      double current_view_width = screen_width / matrix.length;

      bool current_view_is_portrait = current_view_height > current_view_width;

      double ratio_difference = current_view_is_portrait
          ? current_view_height / current_view_width
          : current_view_width / current_view_height;

      ratio_difference = double.parse(ratio_difference.toStringAsFixed(2));

      matrix[column_index][view_index]['orientation'] = ratio_difference >= 1.2
          ? current_view_is_portrait
              ? SlideshowViewOrientation.portrait
              : SlideshowViewOrientation.landscape
          : SlideshowViewOrientation.square_or_similar;

      matrix[column_index][view_index]['ratio_difference'] = ratio_difference;
    }
  }
  return matrix;
}

List<List<Map<String, dynamic>>> _calculate_possible_positions_for_videos({
  required List<List<Map<String, dynamic>>> matrix,
}) {
  List<Map<String, dynamic>> linear_matrix = [];

  for (var column in matrix) {
    for (var view in column) {
      linear_matrix.add({
        'column_index': matrix.indexOf(column),
        'view_index': column.indexOf(view),
        'orientation': view['orientation'],
        'height': view['height'],
      });
    }
  }

  // Find column and view index for the view with the highest height for portrait orientation
  double highest_height_for_portrait = 0;
  int column_index_for_portrait = 0;
  int view_index_for_portrait = 0;

  for (var item in linear_matrix) {
    if (item['orientation'] == SlideshowViewOrientation.portrait) {
      if (item['height'] > highest_height_for_portrait) {
        highest_height_for_portrait = item['height'];
        column_index_for_portrait = item['column_index'];
        view_index_for_portrait = item['view_index'];
      }
    }
  }

  // Mark that view as possible video position for portrait orientation
  matrix[column_index_for_portrait][view_index_for_portrait]['possible_video_position_for_portrait'] = true;

  // Find column and view index for the view with the highest height for landscape orientation
  double highest_height_for_landscape = 0;
  int column_index_for_landscape = 0;
  int view_index_for_landscape = 0;

  for (var item in linear_matrix) {
    if (item['orientation'] == SlideshowViewOrientation.landscape) {
      if (item['height'] > highest_height_for_landscape) {
        //
        // Validate that it's not the same view selected for portrait orientation

        if (item['column_index'] != column_index_for_portrait || item['view_index'] != view_index_for_portrait) {
          highest_height_for_landscape = item['height'];
          column_index_for_landscape = item['column_index'];
          view_index_for_landscape = item['view_index'];
        }
      }
    }
  }

  // Mark that view as possible video position for landscape orientation
  matrix[column_index_for_landscape][view_index_for_landscape]['possible_video_position_for_landscape'] = true;

  return matrix;
}
