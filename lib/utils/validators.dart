class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese un correo electrónico';
    }
    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
    );
    if (!emailRegExp.hasMatch(value)) {
      return 'Por favor ingrese un correo electrónico válido';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese una contraseña';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  static String? validateNewPassword(String? value) {
    final passwordError = validatePassword(value);
    if (passwordError != null) {
      return passwordError;
    }

    final hasNumber = RegExp(r'[0-9]').hasMatch(value!);
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(value);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(value);
    final hasSpecialCharacter = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value);

    if (!hasNumber) {
      return 'La contraseña debe contener al menos un número';
    }
    if (!hasUppercase) {
      return 'La contraseña debe contener al menos una mayúscula';
    }
    if (!hasLowercase) {
      return 'La contraseña debe contener al menos una minúscula';
    }
    if (!hasSpecialCharacter) {
      return 'La contraseña debe contener al menos un carácter especial';
    }

    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Por favor confirme la contraseña';
    }
    if (value != password) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese $fieldName';
    }
    return null;
  }

  static String? validateDeviceName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese un nombre para el dispositivo';
    }
    if (value.length < 3) {
      return 'El nombre debe tener al menos 3 caracteres';
    }
    return null;
  }

  static String? validateNotificationTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese un título';
    }
    if (value.length < 3) {
      return 'El título debe tener al menos 3 caracteres';
    }
    if (value.length > 100) {
      return 'El título no puede tener más de 100 caracteres';
    }
    return null;
  }

  static String? validateNotificationMessage(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingrese un mensaje';
    }
    if (value.length < 10) {
      return 'El mensaje debe tener al menos 10 caracteres';
    }
    if (value.length > 500) {
      return 'El mensaje no puede tener más de 500 caracteres';
    }
    return null;
  }
}