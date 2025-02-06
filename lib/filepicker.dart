import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:excel/excel.dart';

Future<({Map<String, List<List<dynamic>>> data, bool success, String message})> pickFile() async {
  Map<String, List<List<dynamic>>> tempData = {};

  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['xlsx'],
    allowMultiple: false,
    withData: true,
  );

  if (result != null) {
    PlatformFile file = result.files.first;
    Uint8List? fileBytes = file.bytes;

    if (fileBytes != null) {
      try {
        final Excel excel = Excel.decodeBytes(fileBytes);
        
        for (var table in excel.tables.keys) {
          List<List<dynamic>> rows = [];

          for (var row in excel.tables[table]!.rows) {
            List<dynamic> convertedRow = [];

            for (int colIndex = 0; colIndex < row.length; colIndex++) {
              var cell = row[colIndex];
              if (cell?.value != null) {
                var value = cell?.value;
                if (colIndex == 0) {
                  convertedRow.add(value.toString());
                } else {
                  convertedRow.add(value);
                }
              } else {
                convertedRow.add(""); // セルがnullの場合は空文字列を追加
              }
            }
            bool isEmptyRow = (convertedRow[0] == "" || convertedRow[1] == "" || convertedRow[2] == "");
            if (!isEmptyRow) {
              rows.add(convertedRow);
            }
          }
          tempData[table] = rows;
        }

        return (data: tempData, success: true, message: "リストが正常に読み込まれました");
      } catch (e) {
        return (data: tempData, success: false, message: "エラー: $e");
      }
    } else {
      return (data: tempData, success: false, message: "データを読み込めませんでした");
    }
  }
  return (data: tempData, success: false, message: "なにも選択されませんでした");
}