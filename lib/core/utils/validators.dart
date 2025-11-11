class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập email';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email không hợp lệ';
    }

    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }

    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }

    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng xác nhận mật khẩu';
    }

    if (value != password) {
      return 'Mật khẩu không khớp';
    }

    return null;
  }

  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập họ tên';
    }

    if (value.length < 2) {
      return 'Họ tên phải có ít nhất 2 ký tự';
    }

    return null;
  }

  // Phone validation
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập số điện thoại';
    }

    final phoneRegex = RegExp(r'^[0-9]{10,11}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Số điện thoại không hợp lệ';
    }

    return null;
  }

  // Required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập $fieldName';
    }
    return null;
  }

  // Min length validation
  static String? validateMinLength(String? value, int minLength) {
    if (value == null || value.isEmpty) {
      return 'Trường này không được để trống';
    }

    if (value.length < minLength) {
      return 'Phải có ít nhất $minLength ký tự';
    }

    return null;
  }

  // Max length validation
  static String? validateMaxLength(String? value, int maxLength) {
    if (value != null && value.length > maxLength) {
      return 'Không được vượt quá $maxLength ký tự';
    }

    return null;
  }

  // URL validation
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập URL';
    }

    final urlRegex = RegExp(
      r'^(http|https):\/\/([\w-]+\.)+[\w-]+(\/[\w- .\/?%&=]*)?$',
    );

    if (!urlRegex.hasMatch(value)) {
      return 'URL không hợp lệ';
    }

    return null;
  }

  // Number validation
  static String? validateNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập số';
    }

    if (double.tryParse(value) == null) {
      return 'Giá trị phải là số';
    }

    return null;
  }

  // Integer validation
  static String? validateInteger(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập số nguyên';
    }

    if (int.tryParse(value) == null) {
      return 'Giá trị phải là số nguyên';
    }

    return null;
  }

  // Range validation
  static String? validateRange(String? value, double min, double max) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập giá trị';
    }

    final number = double.tryParse(value);
    if (number == null) {
      return 'Giá trị phải là số';
    }

    if (number < min || number > max) {
      return 'Giá trị phải từ $min đến $max';
    }

    return null;
  }

  // Date validation
  static String? validateDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập ngày';
    }

    try {
      DateTime.parse(value);
      return null;
    } catch (e) {
      return 'Định dạng ngày không hợp lệ';
    }
  }

  // Private constructor to prevent instantiation
  Validators._();
}
