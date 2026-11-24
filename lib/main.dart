import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

const String kBaseUrl = 'http://localhost/api-test/public';

void main() => runApp(const CvApp());

class Exp {
  final String year;
  final String titre;
  final String lieu;
  const Exp(this.year, this.titre, this.lieu);
}

class Langue {
  final String nom;
  final int niveau;
  final String label;
  const Langue(this.nom, this.niveau, this.label);
}

class Membre {
  final int? id;
  final String nom;
  final String postnom;
  final String prenom;
  final String lieuNaissance;
  final String dateNaissance;
  final String parente;
  final String? imageUrl;

  Membre({
    this.id,
    required this.nom,
    required this.postnom,
    required this.prenom,
    required this.lieuNaissance,
    required this.dateNaissance,
    required this.parente,
    this.imageUrl,
  });

  factory Membre.fromJson(Map<String, dynamic> json) {
    return Membre(
      id: json['id'],
      nom: json['nom'] ?? '',
      postnom: json['postnom'] ?? '',
      prenom: json['prenom'] ?? '',
      lieuNaissance: json['lieu_naissance'] ?? '',
      dateNaissance: json['date_naissance'] ?? '',
      parente: json['parente'] ?? '',
      imageUrl: json['image_url'],
    );
  }

  Map<String, String> toJson() {
    return {
      'nom': nom,
      'postnom': postnom,
      'prenom': prenom,
      'lieu_naissance': lieuNaissance,
      'date_naissance': dateNaissance,
      'parente': parente,
    };
  }
}

class Donnees {
  static const prenom = 'Yvonne';
  static const postNom = 'Kobuta';
  static const nomFamille = 'Misanga';
  static const titre = 'Technicienne Réseaux & Télécoms';
  static const photo = 'assets/images/yvonne.jpg';

  static const naissance = '11 juillet 2006';
  static const lieuNaissance = 'Kavumu';
  static const nationalite = 'Congolaise';
  static const adresse = 'Himbi 1, av. du musée, Goma';
  static const adresseCourte = 'Himbi 1, Goma';
  static const telephone = '+243 992 475 278';
  static const email = 'yvonnemisanga08@gmail.com';
  static const instagram = 'yvonne_kobuta';

  static int get age {
    final n = DateTime.now();
    var a = n.year - 2006;
    if (n.month < 7 || (n.month == 7 && n.day < 11)) a--;
    return a;
  }

  static const experiences = <Exp>[
    Exp('2022', 'Stagiaire électricienne', 'Microcentrale de Fomulac-Katana'),
    Exp(
      '2026',
      'Stage en télécommunications',
      'Découverte des équipements et infrastructures',
    ),
    Exp(
      '2026',
      'Réseaux informatiques',
      'Configuration et interconnexion des équipements',
    ),
  ];

  static const competences = [
    'Configuration des réseaux informatiques',
    'Configuration des routeurs et commutateurs',
    'Programmation C# (notions)',
  ];

  static const langues = <Langue>[
    Langue('Français', 3, 'Bien'),
    Langue('Kiswahili', 4, 'Courant'),
    Langue('Anglais', 1, 'Basique'),
  ];

  static const interets = [
    'Nouvelles technologies',
    'Formation et apprentissage',
    'Découverte de nouvelles connaissances',
  ];
}

class ApiService {
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final res = await http.post(
      Uri.parse('$kBaseUrl/accounts/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    }
    throw Exception(data['message'] ?? 'Erreur de connexion');
  }

  static Future<List<Membre>> getMembres() async {
    final res = await http.get(
      Uri.parse('$kBaseUrl/famille-membres'),
      headers: _headers,
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data['data'] as List;
      return list.map((e) => Membre.fromJson(e)).toList();
    }
    throw Exception('Erreur lors du chargement');
  }

  static String _parseError(http.Response res) {
    try {
      final data = jsonDecode(res.body);
      if (data['errors'] != null) {
        return (data['errors'] as Map).values.first.toString();
      }
      return data['message'] ?? 'Erreur inconnue';
    } catch (_) {
      return 'Erreur serveur (${res.statusCode})';
    }
  }

  static Future<void> addMembre(Membre m, {File? image}) async {
    try {
      if (image != null) {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$kBaseUrl/famille-membres'),
        );
        request.headers.addAll({'Accept': 'application/json'});
        request.fields.addAll(m.toJson());
        request.files.add(
          await http.MultipartFile.fromPath('image', image.path),
        );

        final response = await request.send();
        final res = await http.Response.fromStream(response);
        if (res.statusCode != 201) throw Exception(_parseError(res));
      } else {
        final res = await http.post(
          Uri.parse('$kBaseUrl/famille-membres'),
          headers: _headers,
          body: jsonEncode(m.toJson()),
        );
        if (res.statusCode != 201) throw Exception(_parseError(res));
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  static Future<void> updateMembre(Membre m, {File? image}) async {
    try {
      if (image != null) {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$kBaseUrl/famille-membres/${m.id}'),
        );
        request.headers.addAll({'Accept': 'application/json'});
        request.fields.addAll(m.toJson());
        request.files.add(
          await http.MultipartFile.fromPath('image', image.path),
        );

        final response = await request.send();
        final res = await http.Response.fromStream(response);
        if (res.statusCode != 200) throw Exception(_parseError(res));
      } else {
        final res = await http.put(
          Uri.parse('$kBaseUrl/famille-membres/${m.id}'),
          headers: _headers,
          body: jsonEncode(m.toJson()),
        );
        if (res.statusCode != 200) throw Exception(_parseError(res));
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  static Future<void> deleteMembre(int id) async {
    final res = await http.delete(
      Uri.parse('$kBaseUrl/famille-membres/$id'),
      headers: _headers,
    );
    if (res.statusCode != 200) throw Exception('Erreur lors de la suppression');
  }
}

const kBg = Color(0xFFF7F8FA);
const kSurface = Color(0xFFFFFFFF);
const kBorder = Color(0xFFE5E7EB);
const kInk = Color(0xFF0F172A);
const kInk2 = Color(0xFF475569);
const kInk3 = Color(0xFF94A3B8);
const kAccent = Color(0xFF2563EB);
const kAccentSoft = Color(0xFFEFF4FF);
const kDanger = Color(0xFFDC2626);
const kDangerSoft = Color(0xFFFEF2F2);

TextStyle sans(
  double size, {
  FontWeight w = FontWeight.w400,
  Color c = kInk,
  double? h,
  double? ls,
}) => GoogleFonts.plusJakartaSans(
  fontSize: size,
  fontWeight: w,
  color: c,
  height: h,
  letterSpacing: ls,
);

class CvApp extends StatelessWidget {
  const CvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CV Yvonne Kobuta',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kAccent,
          brightness: Brightness.light,
        ).copyWith(primary: kAccent, surface: kSurface, onSurface: kInk),
        scaffoldBackgroundColor: kBg,
        splashFactory: InkSparkle.splashFactory,
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: kAccent,
          selectionColor: kAccent.withOpacity(0.2),
          selectionHandleColor: kAccent,
        ),
      ),
      home: const LoginPage(),
    );
  }
}

class Photo extends StatelessWidget {
  final String? asset;
  final String? networkUrl;
  final String nom;
  final double size;
  final double radius;
  const Photo({
    super.key,
    this.asset,
    this.networkUrl,
    required this.nom,
    this.size = 56,
    this.radius = 10,
  });

  @override
  Widget build(BuildContext context) {
    final initiale = nom.isNotEmpty ? nom[0].toUpperCase() : '?';
    final placeholder = Center(
      child: Text(
        initiale,
        style: sans(size * 0.4, w: FontWeight.w700, c: kAccent),
      ),
    );

    Widget child;
    if (networkUrl != null) {
      child = Image.network(
        networkUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      );
    } else if (asset != null) {
      child = Image.asset(
        asset!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
      );
    } else {
      child = placeholder;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: kAccentSoft,
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class CardBox extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  const CardBox({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kSurface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kBorder),
          ),
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;
  const SectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Icon(icon, size: 16, color: kAccent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: sans(13.5, w: FontWeight.w700, ls: -0.1),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: kBorder),
          ...children,
        ],
      ),
    );
  }
}

class ListRow extends StatelessWidget {
  final Widget? leading;
  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  const ListRow({
    super.key,
    this.leading,
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            Expanded(
              child: Text(
                label,
                style: sans(13.5, w: FontWeight.w500, h: 1.35),
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  value!,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: sans(12.5, c: kInk2, w: FontWeight.w500, h: 1.35),
                ),
              ),
            ],
            if (trailing != null) ...[const SizedBox(width: 6), trailing!],
          ],
        ),
      ),
    );
  }
}

class HairLine extends StatelessWidget {
  const HairLine({super.key});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    height: 1,
    color: kBorder,
  );
}

class Bullet extends StatelessWidget {
  const Bullet({super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: 5,
    height: 5,
    decoration: const BoxDecoration(color: kAccent, shape: BoxShape.circle),
  );
}

void toast(BuildContext context, String msg, {bool isError = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: sans(13, w: FontWeight.w500, c: Colors.white),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 90),
        backgroundColor: isError ? kDanger : kInk,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _idCtrl = TextEditingController();
  final _mdpCtrl = TextEditingController();
  bool _hide = true;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _loading = true;
    });

    try {
      await ApiService.login(_idCtrl.text.trim(), _mdpCtrl.text);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 400),
            pageBuilder: (_, __, ___) => const MainShell(),
            transitionsBuilder: (_, a, __, c) =>
                FadeTransition(opacity: a, child: c),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _mdpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: kAccentSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'YK',
                    style: sans(14, w: FontWeight.w800, c: kAccent, ls: -0.5),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Connexion',
                style: sans(32, w: FontWeight.w800, h: 1.1, ls: -0.8),
              ),
              const SizedBox(height: 8),
              Text(
                'Accédez au CV de Yvonne Kobuta.',
                style: sans(14, c: kInk2, h: 1.4),
              ),
              const SizedBox(height: 40),

              _field(
                'Identifiant (Email)',
                _idCtrl,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 18),
              _field(
                'Mot de passe',
                _mdpCtrl,
                obscure: _hide,
                onSubmitted: (_) => _submit(),
                suffix: IconButton(
                  iconSize: 20,
                  splashRadius: 20,
                  icon: Icon(
                    _hide
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: kInk3,
                  ),
                  onPressed: () => setState(() => _hide = !_hide),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: kDangerSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 16, color: kDanger),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: sans(12.5, w: FontWeight.w500, c: kDanger),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: kAccent,
                    disabledBackgroundColor: kAccent.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Se connecter',
                          style: sans(15, w: FontWeight.w700, c: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    bool obscure = false,
    Widget? suffix,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(label, style: sans(13, w: FontWeight.w600)),
        ),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          cursorColor: kAccent,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          style: sans(15, w: FontWeight.w500),
          decoration: InputDecoration(
            filled: true,
            fillColor: kSurface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 15,
            ),
            suffixIcon: suffix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _i = 0;

  void _logout() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => const LoginPage(),
        transitionsBuilder: (_, a, __, c) =>
            FadeTransition(opacity: a, child: c),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      AccueilPage(onLogout: _logout),
      const FamillePage(),
      const ContactPage(),
    ];
    return Scaffold(
      backgroundColor: kBg,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: KeyedSubtree(key: ValueKey(_i), child: pages[_i]),
      ),
      bottomNavigationBar: _NavBar(
        index: _i,
        onChange: (v) => setState(() => _i = v),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChange;
  const _NavBar({required this.index, required this.onChange});

  static const _items = [
    (icon: Icons.home_outlined, active: Icons.home_rounded, label: 'Accueil'),
    (
      icon: Icons.people_outline_rounded,
      active: Icons.people_rounded,
      label: 'Famille',
    ),
    (
      icon: Icons.mail_outline_rounded,
      active: Icons.mail_rounded,
      label: 'Contact',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: kSurface,
        border: Border(top: BorderSide(color: kBorder)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              for (int i = 0; i < _items.length; i++) Expanded(child: _item(i)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(int i) {
    final active = i == index;
    final it = _items[i];
    return InkWell(
      onTap: () => onChange(i),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 56,
            height: 28,
            decoration: BoxDecoration(
              color: active ? kAccentSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              active ? it.active : it.icon,
              size: 22,
              color: active ? kAccent : kInk3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            it.label,
            style: sans(
              11,
              w: active ? FontWeight.w700 : FontWeight.w500,
              c: active ? kAccent : kInk3,
            ),
          ),
        ],
      ),
    );
  }
}

class AccueilPage extends StatelessWidget {
  final VoidCallback? onLogout;
  const AccueilPage({super.key, this.onLogout});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mon CV',
                    style: sans(13.5, w: FontWeight.w600, c: kInk2),
                  ),
                  Material(
                    color: kSurface,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: onLogout,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: kBorder),
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          size: 17,
                          color: kInk2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _profileCard(),
                  const SizedBox(height: 20),

                  SectionCard(
                    icon: Icons.person_outline_rounded,
                    title: 'Identité',
                    children: [
                      ListRow(
                        label: 'Date de naissance',
                        value: Donnees.naissance,
                      ),
                      const HairLine(),
                      ListRow(
                        label: 'Lieu de naissance',
                        value: Donnees.lieuNaissance,
                      ),
                      const HairLine(),
                      ListRow(label: 'Nationalité', value: Donnees.nationalite),
                      const HairLine(),
                      ListRow(label: 'Adresse', value: Donnees.adresseCourte),
                    ],
                  ),
                  const SizedBox(height: 16),

                  SectionCard(
                    icon: Icons.work_outline_rounded,
                    title: 'Expérience professionnelle',
                    children: [
                      for (int i = 0; i < Donnees.experiences.length; i++) ...[
                        if (i > 0) const HairLine(),
                        _expRow(Donnees.experiences[i]),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  SectionCard(
                    icon: Icons.terminal_rounded,
                    title: 'Compétences techniques',
                    children: [
                      for (int i = 0; i < Donnees.competences.length; i++) ...[
                        if (i > 0) const HairLine(),
                        ListRow(
                          leading: const Bullet(),
                          label: Donnees.competences[i],
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  SectionCard(
                    icon: Icons.translate_rounded,
                    title: 'Langues',
                    children: [
                      for (int i = 0; i < Donnees.langues.length; i++) ...[
                        if (i > 0) const HairLine(),
                        _langRow(Donnees.langues[i]),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  SectionCard(
                    icon: Icons.favorite_border_rounded,
                    title: "Centres d'intérêt",
                    children: [
                      for (int i = 0; i < Donnees.interets.length; i++) ...[
                        if (i > 0) const HairLine(),
                        ListRow(
                          leading: const Bullet(),
                          label: Donnees.interets[i],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileCard() {
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Photo(
                  asset: Donnees.photo,
                  nom: Donnees.prenom,
                  size: 76,
                  radius: 12,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Donnees.prenom,
                        style: sans(20, w: FontWeight.w800, h: 1.1, ls: -0.4),
                      ),
                      Text(
                        '${Donnees.postNom} ${Donnees.nomFamille}',
                        style: sans(20, w: FontWeight.w800, h: 1.1, ls: -0.4),
                      ),
                      const SizedBox(height: 6),
                      Text(Donnees.titre, style: sans(12.5, c: kInk2, h: 1.4)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: kInk3,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Goma, RDC',
                            style: sans(11.5, c: kInk3, w: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: kBorder),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                _stat('${Donnees.age}', 'ans'),
                _vdiv(),
                _stat('L3', 'niveau'),
                _vdiv(),
                _stat('${Donnees.experiences.length}', 'exp.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String v, String l) => Expanded(
    child: Column(
      children: [
        Text(v, style: sans(18, w: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(
          l,
          style: sans(11, c: kInk3, w: FontWeight.w500),
        ),
      ],
    ),
  );

  Widget _vdiv() => Container(width: 1, height: 28, color: kBorder);

  Widget _expRow(Exp e) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: kAccentSoft,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            e.year,
            style: sans(11, w: FontWeight.w700, c: kAccent),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(e.titre, style: sans(13.5, w: FontWeight.w700, h: 1.35)),
              const SizedBox(height: 3),
              Text(e.lieu, style: sans(12, c: kInk2, h: 1.4)),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _langRow(Langue l) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(
      children: [
        Expanded(
          child: Text(l.nom, style: sans(13.5, w: FontWeight.w500)),
        ),
        for (int i = 0; i < 4; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < l.niveau ? kAccent : kBorder,
            ),
          ),
        ],
        const SizedBox(width: 12),
        SizedBox(
          width: 56,
          child: Text(
            l.label,
            textAlign: TextAlign.right,
            style: sans(11.5, c: kInk3, w: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}

class FamillePage extends StatefulWidget {
  const FamillePage({super.key});
  @override
  State<FamillePage> createState() => _FamillePageState();
}

class _FamillePageState extends State<FamillePage> {
  List<Membre> _membres = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _membres = await ApiService.getMembres();
    } catch (e) {
      if (mounted) toast(context, 'Erreur: $e', isError: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showForm({Membre? membre}) {
    final nomCtrl = TextEditingController(text: membre?.nom ?? '');
    final postnomCtrl = TextEditingController(text: membre?.postnom ?? '');
    final prenomCtrl = TextEditingController(text: membre?.prenom ?? '');
    final lieuCtrl = TextEditingController(text: membre?.lieuNaissance ?? '');
    final dateCtrl = TextEditingController(text: membre?.dateNaissance ?? '');
    final parenteCtrl = TextEditingController(text: membre?.parente ?? '');
    File? image;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: kBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      membre == null
                          ? 'Ajouter un membre'
                          : 'Modifier le membre',
                      style: sans(20, w: FontWeight.w800),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildField('Nom', nomCtrl, required: true),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildField(
                            'Postnom',
                            postnomCtrl,
                            required: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildField('Prénom', prenomCtrl, required: true),
                    const SizedBox(height: 12),
                    _buildField('Lieu de naissance', lieuCtrl, required: true),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: dateCtrl,
                      readOnly: true,
                      style: sans(14, w: FontWeight.w500),
                      decoration: _inputDeco(
                        'Date de naissance',
                        suffix: const Icon(
                          Icons.calendar_today,
                          size: 20,
                          color: kInk3,
                        ),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setSheetState(() {
                            dateCtrl.text = DateFormat('yyyy-MM-dd')
                                .format(picked);
                          });
                        }
                      },
                      validator: (v) => v!.isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      'Lien de parenté (ex: Père)',
                      parenteCtrl,
                      required: true,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (picked != null)
                          setSheetState(() => image = File(picked.path));
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: kBorder),
                        foregroundColor: kAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.image_outlined),
                      label: Text(
                        image == null
                            ? 'Choisir une photo (Optionnel)'
                            : 'Photo sélectionnée',
                        style: sans(13, w: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;

                          final m = Membre(
                            id: membre?.id,
                            nom: nomCtrl.text,
                            postnom: postnomCtrl.text,
                            prenom: prenomCtrl.text,
                            lieuNaissance: lieuCtrl.text,
                            dateNaissance: dateCtrl.text,
                            parente: parenteCtrl.text,
                          );

                          try {
                            if (membre == null) {
                              await ApiService.addMembre(m, image: image);
                            } else {
                              await ApiService.updateMembre(m, image: image);
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                            _load();
                          } catch (e) {
                            if (ctx.mounted)
                              toast(ctx, 'Erreur: $e', isError: true);
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: kAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Enregistrer',
                          style: sans(15, w: FontWeight.w700, c: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl, {
    bool required = false,
  }) {
    return TextFormField(
      controller: ctrl,
      style: sans(14, w: FontWeight.w500),
      decoration: _inputDeco(label),
      validator: (v) => (required && v!.isEmpty) ? 'Requis' : null,
    );
  }

  InputDecoration _inputDeco(String label, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: sans(13, c: kInk2),
      suffixIcon: suffix,
      filled: true,
      fillColor: kBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kAccent, width: 1.5),
      ),
    );
  }

  void _delete(Membre m) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Supprimer', style: sans(18, w: FontWeight.bold)),
        content: Text('Voulez-vous supprimer ${m.nom} ?', style: sans(14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler', style: sans(14, c: kInk2)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kDanger),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService.deleteMembre(m.id!);
                _load();
              } catch (e) {
                if (context.mounted) toast(context, '$e', isError: true);
              }
            },
            child: Text('Supprimer', style: sans(14, c: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        backgroundColor: kAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: kAccent))
            : SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        'Famille',
                        style: sans(28, w: FontWeight.w800, ls: -0.6),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Les personnes qui comptent.',
                        style: sans(13.5, c: kInk2, h: 1.4),
                      ),
                      const SizedBox(height: 24),

                      if (_membres.isEmpty)
                        CardBox(
                          padding: const EdgeInsets.all(30),
                          child: Center(
                            child: Text(
                              'Aucun membre pour le moment.',
                              style: sans(14, c: kInk3),
                            ),
                          ),
                        )
                      else
                        SectionCard(
                          icon: Icons.groups_outlined,
                          title: '${_membres.length} membres',
                          children: [
                            for (int i = 0; i < _membres.length; i++) ...[
                              if (i > 0) const HairLine(),
                              _memberRow(_membres[i]),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _memberRow(Membre m) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Row(
      children: [
        Photo(networkUrl: m.imageUrl, nom: m.nom, size: 44, radius: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${m.prenom} ${m.nom}',
                style: sans(14, w: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                m.lieuNaissance,
                style: sans(12, c: kInk2, w: FontWeight.w500),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: kBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: kBorder),
          ),
          child: Text(
            m.parente,
            style: sans(10.5, w: FontWeight.w600, c: kInk2),
          ),
        ),
        PopupMenuButton<String>(
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.more_vert, color: kInk3, size: 20),
          onSelected: (val) {
            if (val == 'edit') _showForm(membre: m);
            if (val == 'delete') _delete(m);
          },
          itemBuilder: (c) => [
            const PopupMenuItem(value: 'edit', child: Text('Modifier')),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Supprimer', style: TextStyle(color: kDanger)),
            ),
          ],
        ),
      ],
    ),
  );
}

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  Future<void> _open(BuildContext context, String url) async {
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) toast(context, "Impossible d'ouvrir");
  }

  Future<void> _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) toast(context, 'Copié dans le presse-papiers');
  }

  @override
  Widget build(BuildContext context) {
    final tel = Donnees.telephone.replaceAll(' ', '');
    final wa = 'https://wa.me/${tel.replaceAll('+', '')}';

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text('Contact', style: sans(28, w: FontWeight.w800, ls: -0.6)),
              const SizedBox(height: 6),
              Text('Discutons ensemble.', style: sans(13.5, c: kInk2, h: 1.4)),
              const SizedBox(height: 24),

              Row(
                children: [
                  _action(
                    context,
                    Icons.call_rounded,
                    'Appeler',
                    () => _open(context, 'tel:$tel'),
                  ),
                  const SizedBox(width: 10),
                  _action(
                    context,
                    Icons.mail_rounded,
                    'E-mail',
                    () => _open(context, 'mailto:${Donnees.email}'),
                  ),
                  const SizedBox(width: 10),
                  _action(
                    context,
                    Icons.chat_rounded,
                    'WhatsApp',
                    () => _open(context, wa),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              SectionCard(
                icon: Icons.contact_mail_outlined,
                title: 'Coordonnées',
                children: [
                  _contactRow(
                    icon: Icons.phone_rounded,
                    label: 'Téléphone',
                    value: Donnees.telephone,
                    onTap: () => _open(context, 'tel:$tel'),
                    onLongPress: () => _copy(context, Donnees.telephone),
                  ),
                  const HairLine(),
                  _contactRow(
                    icon: Icons.email_rounded,
                    label: 'E-mail',
                    value: Donnees.email,
                    onTap: () => _open(context, 'mailto:${Donnees.email}'),
                    onLongPress: () => _copy(context, Donnees.email),
                  ),
                  const HairLine(),
                  _contactRow(
                    icon: Icons.location_on_rounded,
                    label: 'Adresse',
                    value: 'Goma, RD Congo',
                    onTap: () => _copy(context, Donnees.adresse),
                    onLongPress: () => _copy(context, Donnees.adresse),
                  ),
                  const HairLine(),
                  _contactRow(
                    icon: Icons.camera_alt_rounded,
                    label: 'Instagram',
                    value: '@${Donnees.instagram}',
                    onTap: () => _open(
                      context,
                      'https://instagram.com/${Donnees.instagram}',
                    ),
                    onLongPress: () => _copy(context, '@${Donnees.instagram}'),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Center(
                child: Text(
                  'Appui long pour copier',
                  style: sans(11.5, c: kInk3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _action(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: Material(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorder),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Icon(icon, size: 20, color: kAccent),
                const SizedBox(height: 8),
                Text(label, style: sans(12, w: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _contactRow({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: kBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kBorder),
              ),
              child: Icon(icon, size: 16, color: kInk2),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: sans(11.5, c: kInk3, w: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: sans(13.5, w: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: kInk3),
          ],
        ),
      ),
    );
  }
}
