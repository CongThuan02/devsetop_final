/// Validators dùng chung cho TextFormField.
/// Trả về null khi hợp lệ, hoặc thông báo lỗi tiếng Việt.
class Validators {
  static final _emailRegex = RegExp(r'^[\w\.\-+]+@[\w\-]+(\.[\w\-]+)+$');
  static final _urlRegex = RegExp(
    r'^(https?:\/\/)?([\w\-]+\.)+[\w\-]{2,}(\/[^\s]*)?$',
  );

  static String? required(String? v, {String label = 'Trường này'}) {
    if (v == null || v.trim().isEmpty) return '$label không được để trống.';
    return null;
  }

  static String? email(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'Thư điện tử không được để trống.';
    if (!_emailRegex.hasMatch(t)) return 'Thư điện tử không hợp lệ.';
    return null;
  }

  /// Mật khẩu chính (master password) — yêu cầu mạnh hơn.
  static String? masterPassword(String? v) {
    final t = v ?? '';
    if (t.isEmpty) return 'Mật khẩu không được để trống.';
    if (t.length < 12) return 'Mật khẩu phải có ít nhất 12 ký tự.';
    if (!RegExp(r'[A-Z]').hasMatch(t)) {
      return 'Mật khẩu phải có ít nhất 1 chữ hoa.';
    }
    if (!RegExp(r'[a-z]').hasMatch(t)) {
      return 'Mật khẩu phải có ít nhất 1 chữ thường.';
    }
    if (!RegExp(r'[0-9]').hasMatch(t)) {
      return 'Mật khẩu phải có ít nhất 1 chữ số.';
    }
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\\/;`~]').hasMatch(t)) {
      return 'Mật khẩu phải có ít nhất 1 ký tự đặc biệt.';
    }
    return null;
  }

  /// Mật khẩu khi đăng nhập — chỉ check không rỗng (để Firebase quyết).
  static String? signInPassword(String? v) {
    if (v == null || v.isEmpty) return 'Mật khẩu không được để trống.';
    return null;
  }

  /// Mật khẩu lưu trong vault — không yêu cầu mạnh (vì người dùng có thể
  /// lưu mật khẩu sẵn có của dịch vụ khác), chỉ cần không rỗng.
  static String? vaultPassword(String? v) {
    if (v == null || v.isEmpty) return 'Mật khẩu không được để trống.';
    return null;
  }

  static String? serviceName(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'Tên dịch vụ không được để trống.';
    if (t.length > 100) return 'Tên dịch vụ tối đa 100 ký tự.';
    return null;
  }

  /// URL — tuỳ chọn (có thể để trống), nếu nhập thì phải đúng định dạng.
  static String? optionalUrl(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return null;
    if (!_urlRegex.hasMatch(t)) {
      return 'Địa chỉ web không hợp lệ (vd: https://shopee.vn).';
    }
    return null;
  }

  static String? maxLength(String? v, int max, {String label = 'Trường này'}) {
    final t = v ?? '';
    if (t.length > max) return '$label tối đa $max ký tự.';
    return null;
  }
}
