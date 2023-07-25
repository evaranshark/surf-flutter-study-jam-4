import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shake/shake.dart';
import 'package:surf_practice_magic_ball/bloc/magic_ball_bloc.dart';
import 'package:surf_practice_magic_ball/helpers.dart';

class MagicBall extends StatelessWidget {
  const MagicBall({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MagicBallBloc(),
      child: const MagicBallWidget(),
    );
  }
}

class MagicBallWidget extends StatefulWidget {
  const MagicBallWidget({super.key});

  @override
  State<MagicBallWidget> createState() => _MagicBallWidgetState();
}

class _MagicBallWidgetState extends State<MagicBallWidget>
    with TickerProviderStateMixin {
  /// Defines if ball should shake or idle
  bool shaking = false;
  final _successColor = Colors.deepPurple;
  final _errorColor = Colors.red.shade600;
  final _fadeDuration = const Duration(seconds: 2);

  //Animates text and ball fade effects
  late final AnimationController _fadeController;

  //Animates ball bouncing while idle
  late final AnimationController _idleController;

  //Animates shake effects
  late final AnimationController _shakeController;

  //Ball fade animation
  late Animation<Color?> _fadeAnimation =
      ColorTween(begin: targetColor, end: Colors.black)
          .animate(_fadeController);

  //Text opacity
  late final Animation<double> _opacityAnimation =
      Tween<double>(begin: 1, end: 0).animate(_fadeController);

  //Idle animation
  late final Animation<Offset> _idleAnimation = Tween<Offset>(
    begin: const Offset(0, 0.02),
    end: const Offset(0, -0.02),
  ).animate(CurvedAnimation(
    parent: _idleController,
    curve: Curves.ease,
  ));

  //Shake animation
  late final Animation<Offset> _shakeAnimation = Tween<Offset>(
    begin: const Offset(0.02, 0),
    end: const Offset(-0.02, 0),
  ).animate(CurvedAnimation(
    parent: _shakeController,
    curve: Curves.bounceInOut,
  ));

  //Defines what color will [_fadeAnimation] animate to. Affects ball gradient
  late Color targetColor;

  late final ShakeDetector detector;

  @override
  void initState() {
    super.initState();
    targetColor = _successColor;
    _fadeController = AnimationController(vsync: this, duration: _fadeDuration);
    _idleController =
        AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _shakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _idleController.repeat(reverse: true);
    detector = ShakeDetector.waitForStart(onPhoneShake: onTriggered);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _idleController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  /// Called when ball is shaken or pushed
  ///
  /// Stops idle animation, starts shake and fade effects, triggers data load.
  void onTriggered() {
    if (!_fadeController.isAnimating) {
      setState(() {
        shaking = true;
      });
      _idleController.animateTo(0.0).then((value) => _idleController.stop());
      _shakeController.repeat(reverse: true);
      _fadeController
          .forward()
          .then((value) => context.read<MagicBallBloc>().add(Load()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTriggered,
      child: MultiBlocListener(
        listeners: [
          // When turn into loading state, stop listening to shake moves to avoid excessive operations
          BlocListener<MagicBallBloc, MagicBallBlocState>(
            listener: (context, state) {
              if (Helpers.isMobile) {
                detector.stopListening();
              }
            },
            listenWhen: (previous, current) {
              return current is MagicBallLoadingState;
            },
          ),

          /// When load completed (or failed):
          /// * Start listening to shake moves
          /// * Stop shake animattion
          /// * Remain idle animation
          BlocListener<MagicBallBloc, MagicBallBlocState>(
            listener: (context, state) {
              if (Helpers.isMobile) {
                detector.startListening();
              }
              _shakeController
                  .animateTo(0)
                  .then((value) => _shakeController.stop());
              _idleController.repeat(reverse: true);
              setState(() {
                shaking = false;
              });
            },
            listenWhen: (previous, current) {
              return previous is MagicBallLoadingState;
            },
          ),

          /// If successfully retrieved data, fade in with "success" color
          BlocListener<MagicBallBloc, MagicBallBlocState>(
            listener: (context, state) {
              setState(() {
                targetColor = _successColor;
                _fadeAnimation =
                    ColorTween(begin: targetColor, end: Colors.black)
                        .animate(_fadeController);
              });
              _fadeController.reverse();
            },
            listenWhen: (previous, current) => current is MagicBallHasDataState,
          ),

          /// If data retrieving faile, fade in with "error" color
          BlocListener<MagicBallBloc, MagicBallBlocState>(
            listener: (context, state) {
              setState(() {
                targetColor = _errorColor;
                _fadeAnimation =
                    ColorTween(begin: targetColor, end: Colors.black)
                        .animate(_fadeController);
              });
              _fadeController.reverse();
            },
            listenWhen: (previous, current) =>
                current is MagicBallHasErrorState,
          )
        ],
        child: SlideTransition(
          position: shaking ? _shakeAnimation : _idleAnimation,
          child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return DecoratedBox(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: _fadeAnimation.value ?? Colors.deepPurple,
                        blurRadius: 10,
                      )
                    ],
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                        colors: [Colors.black, Colors.deepPurple], radius: 0.8),
                  ),
                  child: AnimatedBuilder(
                      animation: _fadeAnimation,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                _fadeAnimation.value ?? Colors.transparent,
                                Colors.transparent
                              ],
                              radius: 1.5,
                            ),
                          ),
                          child: AnimatedBuilder(
                              animation: _opacityAnimation,
                              builder: (context, child) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: MagicBallText(
                                        opacity: _opacityAnimation.value),
                                  ),
                                );
                              }),
                        );
                      }),
                );
              }),
        ),
      ),
    );
  }
}

class MagicBallText extends StatelessWidget {
  const MagicBallText({
    super.key,
    required double opacity,
  }) : _opacity = opacity;

  final double _opacity;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MagicBallBloc, MagicBallBlocState>(
        builder: (context, state) {
      if (state is MagicBallHasDataState) {
        return Opacity(
          opacity: _opacity,
          child: ResponsiveText(
            text: state.data,
          ),
        );
      }
      if (state is MagicBallHasErrorState) {
        return Opacity(
          opacity: _opacity,
          child: ResponsiveText(
            text: state.error,
          ),
        );
      }
      return Opacity(
        opacity: _opacity,
      );
    });
  }
}

class ResponsiveText extends StatelessWidget {
  final String text;
  const ResponsiveText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    double fontSize;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth) {
          fontSize = 14;
        } else {
          switch (constraints.maxWidth) {
            case < 100:
              fontSize = 14;
            case < 200:
              fontSize = 16;
            case < 300:
              fontSize = 18;
            case _:
              fontSize = 24;
          }
        }
        return Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.rubik(
            fontSize: fontSize,
          ),
        );
      },
    );
  }
}
