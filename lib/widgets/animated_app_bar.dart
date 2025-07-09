import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AnimatedAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final Color color;
  final Color textColor;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;

  const AnimatedAppBar({
    super.key,
    required this.title,
    this.color = Colors.white,
    this.textColor = const Color(0xFF005DFF),
    this.showBackButton = true,
    this.onBackPressed,
    this.actions,
  });

  @override
  State<AnimatedAppBar> createState() => _AnimatedAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _AnimatedAppBarState extends State<AnimatedAppBar> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: widget.color,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: 
            widget.textColor.computeLuminance() > 0.5 
                ? Brightness.dark 
                : Brightness.light,
      ),
      leading: widget.showBackButton 
          ? IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: widget.textColor),
              onPressed: widget.onBackPressed ?? () => Navigator.pop(context),
            ) 
          : null,
      title: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: Text(
            widget.title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: widget.textColor,
            ),
          ),
        ),
      ),
      actions: widget.actions,
    );
  }
}
