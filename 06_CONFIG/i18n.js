/**
 * Internationalization Configuration
 * Supports multiple languages and locales
 */

const i18n = {
  // Default configuration
  defaultLocale: 'en',
  locales: ['en', 'es', 'fr', 'de', 'zh', 'ja'],
  fallbackLocale: 'en',

  // Translation resources
  resources: {
    en: {
      common: {
        welcome: 'Welcome',
        loading: 'Loading...',
        error: 'Error',
        success: 'Success',
        cancel: 'Cancel',
        confirm: 'Confirm',
        save: 'Save',
        delete: 'Delete',
        edit: 'Edit',
        create: 'Create',
        search: 'Search',
        filter: 'Filter',
        sort: 'Sort',
        export: 'Export',
        import: 'Import',
        download: 'Download',
        upload: 'Upload',
        refresh: 'Refresh',
        back: 'Back',
        next: 'Next',
        previous: 'Previous',
        close: 'Close',
        open: 'Open',
        yes: 'Yes',
        no: 'No'
      },
      auth: {
        login: 'Login',
        logout: 'Logout',
        register: 'Register',
        forgotPassword: 'Forgot Password',
        resetPassword: 'Reset Password',
        changePassword: 'Change Password',
        email: 'Email',
        password: 'Password',
        confirmPassword: 'Confirm Password',
        rememberMe: 'Remember Me',
        loginSuccess: 'Login successful',
        loginError: 'Login failed',
        registerSuccess: 'Registration successful',
        registerError: 'Registration failed'
      },
      user: {
        profile: 'Profile',
        settings: 'Settings',
        preferences: 'Preferences',
        account: 'Account',
        firstName: 'First Name',
        lastName: 'Last Name',
        username: 'Username',
        bio: 'Bio',
        location: 'Location',
        timezone: 'Timezone',
        language: 'Language',
        theme: 'Theme',
        notifications: 'Notifications'
      },
      errors: {
        networkError: 'Network error',
        serverError: 'Server error',
        validationError: 'Validation error',
        unauthorized: 'Unauthorized',
        forbidden: 'Forbidden',
        notFound: 'Not found',
        timeout: 'Request timeout',
        unknown: 'Unknown error'
      },
      validation: {
        required: 'This field is required',
        email: 'Please enter a valid email',
        minLength: 'Minimum length is {{min}} characters',
        maxLength: 'Maximum length is {{max}} characters',
        passwordMismatch: 'Passwords do not match',
        invalidFormat: 'Invalid format'
      }
    },
    es: {
      common: {
        welcome: 'Bienvenido',
        loading: 'Cargando...',
        error: 'Error',
        success: 'Éxito',
        cancel: 'Cancelar',
        confirm: 'Confirmar',
        save: 'Guardar',
        delete: 'Eliminar',
        edit: 'Editar',
        create: 'Crear',
        search: 'Buscar',
        filter: 'Filtrar',
        sort: 'Ordenar',
        export: 'Exportar',
        import: 'Importar',
        download: 'Descargar',
        upload: 'Subir',
        refresh: 'Actualizar',
        back: 'Atrás',
        next: 'Siguiente',
        previous: 'Anterior',
        close: 'Cerrar',
        open: 'Abrir',
        yes: 'Sí',
        no: 'No'
      },
      auth: {
        login: 'Iniciar Sesión',
        logout: 'Cerrar Sesión',
        register: 'Registrarse',
        forgotPassword: 'Olvidé mi Contraseña',
        resetPassword: 'Restablecer Contraseña',
        changePassword: 'Cambiar Contraseña',
        email: 'Correo Electrónico',
        password: 'Contraseña',
        confirmPassword: 'Confirmar Contraseña',
        rememberMe: 'Recordarme',
        loginSuccess: 'Inicio de sesión exitoso',
        loginError: 'Error al iniciar sesión',
        registerSuccess: 'Registro exitoso',
        registerError: 'Error en el registro'
      },
      user: {
        profile: 'Perfil',
        settings: 'Configuración',
        preferences: 'Preferencias',
        account: 'Cuenta',
        firstName: 'Nombre',
        lastName: 'Apellido',
        username: 'Nombre de Usuario',
        bio: 'Biografía',
        location: 'Ubicación',
        timezone: 'Zona Horaria',
        language: 'Idioma',
        theme: 'Tema',
        notifications: 'Notificaciones'
      },
      errors: {
        networkError: 'Error de red',
        serverError: 'Error del servidor',
        validationError: 'Error de validación',
        unauthorized: 'No autorizado',
        forbidden: 'Prohibido',
        notFound: 'No encontrado',
        timeout: 'Tiempo de espera agotado',
        unknown: 'Error desconocido'
      },
      validation: {
        required: 'Este campo es obligatorio',
        email: 'Por favor ingrese un correo válido',
        minLength: 'La longitud mínima es {{min}} caracteres',
        maxLength: 'La longitud máxima es {{max}} caracteres',
        passwordMismatch: 'Las contraseñas no coinciden',
        invalidFormat: 'Formato inválido'
      }
    },
    fr: {
      common: {
        welcome: 'Bienvenue',
        loading: 'Chargement...',
        error: 'Erreur',
        success: 'Succès',
        cancel: 'Annuler',
        confirm: 'Confirmer',
        save: 'Sauvegarder',
        delete: 'Supprimer',
        edit: 'Modifier',
        create: 'Créer',
        search: 'Rechercher',
        filter: 'Filtrer',
        sort: 'Trier',
        export: 'Exporter',
        import: 'Importer',
        download: 'Télécharger',
        upload: 'Téléverser',
        refresh: 'Actualiser',
        back: 'Retour',
        next: 'Suivant',
        previous: 'Précédent',
        close: 'Fermer',
        open: 'Ouvrir',
        yes: 'Oui',
        no: 'Non'
      },
      auth: {
        login: 'Connexion',
        logout: 'Déconnexion',
        register: 'S\'inscrire',
        forgotPassword: 'Mot de passe oublié',
        resetPassword: 'Réinitialiser le mot de passe',
        changePassword: 'Changer le mot de passe',
        email: 'E-mail',
        password: 'Mot de passe',
        confirmPassword: 'Confirmer le mot de passe',
        rememberMe: 'Se souvenir de moi',
        loginSuccess: 'Connexion réussie',
        loginError: 'Échec de la connexion',
        registerSuccess: 'Inscription réussie',
        registerError: 'Échec de l\'inscription'
      },
      user: {
        profile: 'Profil',
        settings: 'Paramètres',
        preferences: 'Préférences',
        account: 'Compte',
        firstName: 'Prénom',
        lastName: 'Nom',
        username: 'Nom d\'utilisateur',
        bio: 'Biographie',
        location: 'Localisation',
        timezone: 'Fuseau horaire',
        language: 'Langue',
        theme: 'Thème',
        notifications: 'Notifications'
      },
      errors: {
        networkError: 'Erreur réseau',
        serverError: 'Erreur serveur',
        validationError: 'Erreur de validation',
        unauthorized: 'Non autorisé',
        forbidden: 'Interdit',
        notFound: 'Non trouvé',
        timeout: 'Délai d\'attente dépassé',
        unknown: 'Erreur inconnue'
      },
      validation: {
        required: 'Ce champ est obligatoire',
        email: 'Veuillez saisir un e-mail valide',
        minLength: 'La longueur minimale est {{min}} caractères',
        maxLength: 'La longueur maximale est {{max}} caractères',
        passwordMismatch: 'Les mots de passe ne correspondent pas',
        invalidFormat: 'Format invalide'
      }
    },
    de: {
      common: {
        welcome: 'Willkommen',
        loading: 'Laden...',
        error: 'Fehler',
        success: 'Erfolg',
        cancel: 'Abbrechen',
        confirm: 'Bestätigen',
        save: 'Speichern',
        delete: 'Löschen',
        edit: 'Bearbeiten',
        create: 'Erstellen',
        search: 'Suchen',
        filter: 'Filtern',
        sort: 'Sortieren',
        export: 'Exportieren',
        import: 'Importieren',
        download: 'Herunterladen',
        upload: 'Hochladen',
        refresh: 'Aktualisieren',
        back: 'Zurück',
        next: 'Weiter',
        previous: 'Vorherige',
        close: 'Schließen',
        open: 'Öffnen',
        yes: 'Ja',
        no: 'Nein'
      },
      auth: {
        login: 'Anmelden',
        logout: 'Abmelden',
        register: 'Registrieren',
        forgotPassword: 'Passwort vergessen',
        resetPassword: 'Passwort zurücksetzen',
        changePassword: 'Passwort ändern',
        email: 'E-Mail',
        password: 'Passwort',
        confirmPassword: 'Passwort bestätigen',
        rememberMe: 'Angemeldet bleiben',
        loginSuccess: 'Anmeldung erfolgreich',
        loginError: 'Anmeldung fehlgeschlagen',
        registerSuccess: 'Registrierung erfolgreich',
        registerError: 'Registrierung fehlgeschlagen'
      },
      user: {
        profile: 'Profil',
        settings: 'Einstellungen',
        preferences: 'Präferenzen',
        account: 'Konto',
        firstName: 'Vorname',
        lastName: 'Nachname',
        username: 'Benutzername',
        bio: 'Biografie',
        location: 'Standort',
        timezone: 'Zeitzone',
        language: 'Sprache',
        theme: 'Thema',
        notifications: 'Benachrichtigungen'
      },
      errors: {
        networkError: 'Netzwerkfehler',
        serverError: 'Serverfehler',
        validationError: 'Validierungsfehler',
        unauthorized: 'Nicht autorisiert',
        forbidden: 'Verboten',
        notFound: 'Nicht gefunden',
        timeout: 'Zeitüberschreitung',
        unknown: 'Unbekannter Fehler'
      },
      validation: {
        required: 'Dieses Feld ist erforderlich',
        email: 'Bitte geben Sie eine gültige E-Mail ein',
        minLength: 'Mindestlänge beträgt {{min}} Zeichen',
        maxLength: 'Maximallänge beträgt {{max}} Zeichen',
        passwordMismatch: 'Passwörter stimmen nicht überein',
        invalidFormat: 'Ungültiges Format'
      }
    },
    zh: {
      common: {
        welcome: '欢迎',
        loading: '加载中...',
        error: '错误',
        success: '成功',
        cancel: '取消',
        confirm: '确认',
        save: '保存',
        delete: '删除',
        edit: '编辑',
        create: '创建',
        search: '搜索',
        filter: '筛选',
        sort: '排序',
        export: '导出',
        import: '导入',
        download: '下载',
        upload: '上传',
        refresh: '刷新',
        back: '返回',
        next: '下一页',
        previous: '上一页',
        close: '关闭',
        open: '打开',
        yes: '是',
        no: '否'
      },
      auth: {
        login: '登录',
        logout: '登出',
        register: '注册',
        forgotPassword: '忘记密码',
        resetPassword: '重置密码',
        changePassword: '修改密码',
        email: '邮箱',
        password: '密码',
        confirmPassword: '确认密码',
        rememberMe: '记住我',
        loginSuccess: '登录成功',
        loginError: '登录失败',
        registerSuccess: '注册成功',
        registerError: '注册失败'
      },
      user: {
        profile: '个人资料',
        settings: '设置',
        preferences: '偏好设置',
        account: '账户',
        firstName: '名',
        lastName: '姓',
        username: '用户名',
        bio: '个人简介',
        location: '位置',
        timezone: '时区',
        language: '语言',
        theme: '主题',
        notifications: '通知'
      },
      errors: {
        networkError: '网络错误',
        serverError: '服务器错误',
        validationError: '验证错误',
        unauthorized: '未授权',
        forbidden: '禁止访问',
        notFound: '未找到',
        timeout: '请求超时',
        unknown: '未知错误'
      },
      validation: {
        required: '此字段为必填项',
        email: '请输入有效的邮箱地址',
        minLength: '最小长度为 {{min}} 个字符',
        maxLength: '最大长度为 {{max}} 个字符',
        passwordMismatch: '密码不匹配',
        invalidFormat: '格式无效'
      }
    },
    ja: {
      common: {
        welcome: 'ようこそ',
        loading: '読み込み中...',
        error: 'エラー',
        success: '成功',
        cancel: 'キャンセル',
        confirm: '確認',
        save: '保存',
        delete: '削除',
        edit: '編集',
        create: '作成',
        search: '検索',
        filter: 'フィルター',
        sort: '並び替え',
        export: 'エクスポート',
        import: 'インポート',
        download: 'ダウンロード',
        upload: 'アップロード',
        refresh: '更新',
        back: '戻る',
        next: '次へ',
        previous: '前へ',
        close: '閉じる',
        open: '開く',
        yes: 'はい',
        no: 'いいえ'
      },
      auth: {
        login: 'ログイン',
        logout: 'ログアウト',
        register: '登録',
        forgotPassword: 'パスワードを忘れた',
        resetPassword: 'パスワードをリセット',
        changePassword: 'パスワードを変更',
        email: 'メールアドレス',
        password: 'パスワード',
        confirmPassword: 'パスワードを確認',
        rememberMe: 'ログイン状態を保持',
        loginSuccess: 'ログイン成功',
        loginError: 'ログイン失敗',
        registerSuccess: '登録成功',
        registerError: '登録失敗'
      },
      user: {
        profile: 'プロフィール',
        settings: '設定',
        preferences: '環境設定',
        account: 'アカウント',
        firstName: '名',
        lastName: '姓',
        username: 'ユーザー名',
        bio: '自己紹介',
        location: '場所',
        timezone: 'タイムゾーン',
        language: '言語',
        theme: 'テーマ',
        notifications: '通知'
      },
      errors: {
        networkError: 'ネットワークエラー',
        serverError: 'サーバーエラー',
        validationError: '検証エラー',
        unauthorized: '認証されていません',
        forbidden: 'アクセスが禁止されています',
        notFound: '見つかりません',
        timeout: 'タイムアウト',
        unknown: '不明なエラー'
      },
      validation: {
        required: 'このフィールドは必須です',
        email: '有効なメールアドレスを入力してください',
        minLength: '最小文字数は {{min}} 文字です',
        maxLength: '最大文字数は {{max}} 文字です',
        passwordMismatch: 'パスワードが一致しません',
        invalidFormat: '無効な形式です'
      }
    }
  },

  // Utility functions
  getLocale() {
    return localStorage.getItem('locale') || this.defaultLocale;
  },

  setLocale(locale) {
    if (this.locales.includes(locale)) {
      localStorage.setItem('locale', locale);
      return true;
    }
    return false;
  },

  translate(key, locale = null, params = {}) {
    const currentLocale = locale || this.getLocale();
    const keys = key.split('.');
    let value = this.resources[currentLocale];

    // Validate locale exists
    if (!value) {
      value = this.resources[this.fallbackLocale];
    }

    if (!value) {
      return key; // Return key if translation not found
    }

    // Safely navigate through nested object
    for (const k of keys) {
      if (value && typeof value === 'object' && Object.prototype.hasOwnProperty.call(value, k)) {
        value = value[k];
      } else {
        value = null;
        break;
      }
    }

    if (!value || typeof value !== 'string') {
      return key; // Return key if translation not found
    }

    // Replace parameters safely
    return value.replace(/\{\{(\w+)\}\}/g, (match, param) => {
      return params && typeof params === 'object' && Object.prototype.hasOwnProperty.call(params, param) ? params[param] : match;
    });
  },

  // Date and number formatting
  formatDate(date, locale = null, options = {}) {
    const currentLocale = locale || this.getLocale();
    return new Intl.DateTimeFormat(currentLocale, options).format(date);
  },

  formatNumber(number, locale = null, options = {}) {
    const currentLocale = locale || this.getLocale();
    return new Intl.NumberFormat(currentLocale, options).format(number);
  },

  formatCurrency(amount, currency = 'USD', locale = null) {
    const currentLocale = locale || this.getLocale();
    return new Intl.NumberFormat(currentLocale, {
      style: 'currency',
      currency
    }).format(amount);
  }
};

// Export for different environments
if (typeof module !== 'undefined' && module.exports) {
  module.exports = i18n;
} else if (typeof window !== 'undefined') {
  window.i18n = i18n;
}