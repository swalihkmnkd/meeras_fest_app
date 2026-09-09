import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Position + typography for one text element on the poster, stored in
/// logical 1080x1920 coordinates so the same template renders identically
/// on Android, iOS and Web regardless of screen size.
class PosterTextStyleConfig {
  final double x;
  final double y;
  final double fontSize;
  final String fontWeight; // 'w400' | 'w600' | 'w700' | 'w800' | 'w900'
  final String alignment; // 'left' | 'center' | 'right'
  final int colorValue; // ARGB

  const PosterTextStyleConfig({
    this.x = 100,
    this.y = 100,
    this.fontSize = 40,
    this.fontWeight = 'w700',
    this.alignment = 'center',
    this.colorValue = 0xFFFFFFFF,
  });

  FontWeight get flutterWeight {
    switch (fontWeight) {
      case 'w400':
        return FontWeight.w400;
      case 'w600':
        return FontWeight.w600;
      case 'w800':
        return FontWeight.w800;
      case 'w900':
        return FontWeight.w900;
      default:
        return FontWeight.w700;
    }
  }

  TextAlign get flutterAlign {
    switch (alignment) {
      case 'left':
        return TextAlign.left;
      case 'right':
        return TextAlign.right;
      default:
        return TextAlign.center;
    }
  }

  Color get color => Color(colorValue);

  PosterTextStyleConfig copyWith({
    double? x,
    double? y,
    double? fontSize,
    String? fontWeight,
    String? alignment,
    int? colorValue,
  }) =>
      PosterTextStyleConfig(
        x: x ?? this.x,
        y: y ?? this.y,
        fontSize: fontSize ?? this.fontSize,
        fontWeight: fontWeight ?? this.fontWeight,
        alignment: alignment ?? this.alignment,
        colorValue: colorValue ?? this.colorValue,
      );

  Map<String, dynamic> toMap() => {
    'x': x,
    'y': y,
    'fontSize': fontSize,
    'fontWeight': fontWeight,
    'alignment': alignment,
    'color': colorValue,
  };

  factory PosterTextStyleConfig.fromMap(Map<String, dynamic>? m,
      {double defX = 100, double defY = 100, double defSize = 40}) {
    if (m == null) return PosterTextStyleConfig(x: defX, y: defY, fontSize: defSize);
    return PosterTextStyleConfig(
      x: (m['x'] as num?)?.toDouble() ?? defX,
      y: (m['y'] as num?)?.toDouble() ?? defY,
      fontSize: (m['fontSize'] as num?)?.toDouble() ?? defSize,
      fontWeight: (m['fontWeight'] ?? 'w700').toString(),
      alignment: (m['alignment'] ?? 'center').toString(),
      colorValue: (m['color'] as num?)?.toInt() ?? 0xFFFFFFFF,
    );
  }
}

/// Position + size + crop/shape behaviour for the student photo box.
class PosterImageConfig {
  final double x;
  final double y;
  final double width;
  final double height;
  final bool circular;
  final double borderRadius; // used only when circular == false
  final double borderWidth;
  final int borderColorValue; // ARGB

  const PosterImageConfig({
    this.x = 340,
    this.y = 300,
    this.width = 400,
    this.height = 400,
    this.circular = true,
    this.borderRadius = 0,
    this.borderWidth = 2,
    this.borderColorValue = 0xFFFFFFFF,
  });

  Color get borderColor => Color(borderColorValue);

  PosterImageConfig copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    bool? circular,
    double? borderRadius,
    double? borderWidth,
    int? borderColorValue,
  }) =>
      PosterImageConfig(
        x: x ?? this.x,
        y: y ?? this.y,
        width: width ?? this.width,
        height: height ?? this.height,
        circular: circular ?? this.circular,
        borderRadius: borderRadius ?? this.borderRadius,
        borderWidth: borderWidth ?? this.borderWidth,
        borderColorValue: borderColorValue ?? this.borderColorValue,
      );

  Map<String, dynamic> toMap() => {
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'circular': circular,
    'borderRadius': borderRadius,
    'borderWidth': borderWidth,
    'borderColor': borderColorValue,
  };

  factory PosterImageConfig.fromMap(Map<String, dynamic>? m) {
    if (m == null) return const PosterImageConfig();
    return PosterImageConfig(
      x: (m['x'] as num?)?.toDouble() ?? 340,
      y: (m['y'] as num?)?.toDouble() ?? 300,
      width: (m['width'] as num?)?.toDouble() ?? 400,
      height: (m['height'] as num?)?.toDouble() ?? 400,
      circular: m['circular'] as bool? ?? true,
      borderRadius: (m['borderRadius'] as num?)?.toDouble() ?? 0,
      borderWidth: (m['borderWidth'] as num?)?.toDouble() ?? 2,
      borderColorValue: (m['borderColor'] as num?)?.toInt() ?? 0xFFFFFFFF,
    );
  }
}

/// One rank's poster template — POSTER_TEMPLATES/{rank_1|rank_2|rank_3|default}.
class PosterTemplateModel {
  final String rankKey;
  final int rank; // 1, 2, 3, or 0 for 'default'
  final String backgroundImageUrl;
  final String backgroundStoragePath;
  final PosterImageConfig studentImage;
  final PosterTextStyleConfig studentName;
  final PosterTextStyleConfig score;
  final PosterTextStyleConfig teamName;
  final PosterTextStyleConfig rankLabel;
  final PosterTextStyleConfig programName;
  final DateTime? updatedAt;

  const PosterTemplateModel({
    required this.rankKey,
    required this.rank,
    this.backgroundImageUrl = '',
    this.backgroundStoragePath = '',
    this.studentImage = const PosterImageConfig(),
    this.studentName = const PosterTextStyleConfig(y: 900, fontSize: 56),
    this.score = const PosterTextStyleConfig(y: 980, fontSize: 40),
    this.teamName = const PosterTextStyleConfig(y: 1040, fontSize: 34),
    this.rankLabel = const PosterTextStyleConfig(y: 200, fontSize: 64, fontWeight: 'w900'),
    this.programName = const PosterTextStyleConfig(y: 840, fontSize: 44, fontWeight: 'w800'),
    this.updatedAt,
  });

  bool get isConfigured => backgroundImageUrl.isNotEmpty;

  static int rankNumberFor(String rankKey) {
    switch (rankKey) {
      case 'rank_1':
        return 1;
      case 'rank_2':
        return 2;
      case 'rank_3':
        return 3;
      default:
        return 0;
    }
  }

  /// Maps a student's best-achieved rank to the template document that
  /// should be used for their poster — 4th place and beyond, or students
  /// with no ranked result at all, fall back to 'default'.
  static String rankKeyFor(int rank) {
    if (rank == 1) return 'rank_1';
    if (rank == 2) return 'rank_2';
    if (rank == 3) return 'rank_3';
    return 'default';
  }

  factory PosterTemplateModel.empty(String rankKey) =>
      PosterTemplateModel(rankKey: rankKey, rank: rankNumberFor(rankKey));

  factory PosterTemplateModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final ts = data['updatedAt'];
    return PosterTemplateModel(
      rankKey: doc.id,
      rank: (data['rank'] as num?)?.toInt() ?? rankNumberFor(doc.id),
      backgroundImageUrl: (data['backgroundImageUrl'] ?? '').toString(),
      backgroundStoragePath: (data['backgroundStoragePath'] ?? '').toString(),
      studentImage: PosterImageConfig.fromMap(data['studentImage'] as Map<String, dynamic>?),
      studentName: PosterTextStyleConfig.fromMap(data['studentName'] as Map<String, dynamic>?,
          defY: 900, defSize: 56),
      score: PosterTextStyleConfig.fromMap(data['score'] as Map<String, dynamic>?, defY: 980, defSize: 40),
      teamName:
      PosterTextStyleConfig.fromMap(data['teamName'] as Map<String, dynamic>?, defY: 1040, defSize: 34),
      rankLabel: PosterTextStyleConfig.fromMap(data['rankLabel'] as Map<String, dynamic>?,
          defY: 200, defSize: 64),
      programName: PosterTextStyleConfig.fromMap(data['programName'] as Map<String, dynamic>?,
          defY: 840, defSize: 44),
      updatedAt: ts is Timestamp ? ts.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'rank': rank,
    'backgroundImageUrl': backgroundImageUrl,
    'backgroundStoragePath': backgroundStoragePath,
    'studentImage': studentImage.toMap(),
    'studentName': studentName.toMap(),
    'score': score.toMap(),
    'teamName': teamName.toMap(),
    'rankLabel': rankLabel.toMap(),
    'programName': programName.toMap(),
  };

  PosterTemplateModel copyWith({
    String? backgroundImageUrl,
    String? backgroundStoragePath,
    PosterImageConfig? studentImage,
    PosterTextStyleConfig? studentName,
    PosterTextStyleConfig? score,
    PosterTextStyleConfig? teamName,
    PosterTextStyleConfig? rankLabel,
    PosterTextStyleConfig? programName,
  }) =>
      PosterTemplateModel(
        rankKey: rankKey,
        rank: rank,
        backgroundImageUrl: backgroundImageUrl ?? this.backgroundImageUrl,
        backgroundStoragePath: backgroundStoragePath ?? this.backgroundStoragePath,
        studentImage: studentImage ?? this.studentImage,
        studentName: studentName ?? this.studentName,
        score: score ?? this.score,
        teamName: teamName ?? this.teamName,
        rankLabel: rankLabel ?? this.rankLabel,
        programName: programName ?? this.programName,
        updatedAt: updatedAt,
      );

  /// Read-only fetch used by the public Student Poster screens — kept here,
  /// next to the model, rather than pulled through the admin-only
  /// [PosterTemplateProvider] (which carries unsaved-edit state that a
  /// public/Guest screen should never see).
  static Future<PosterTemplateModel?> fetchByRankKey(String rankKey) async {
    // ⬅️ FIX: force a server read instead of the default "server, falling
    // back to cache" behavior. A plain .get() can silently resolve from
    // Firestore's local cache (especially on web / flaky connections),
    // which is exactly what would make a just-saved template edit not
    // show up here even though it's already written in Firestore. If the
    // server is genuinely unreachable this throws instead of quietly
    // showing stale data — the caller's existing try/catch already
    // surfaces that as an error message.
    final doc = await FirebaseFirestore.instance
        .collection('POSTER_TEMPLATES')
        .doc(rankKey)
        .get(const GetOptions(source: Source.server));
    if (!doc.exists) return null;
    return PosterTemplateModel.fromDoc(doc);
  }
}