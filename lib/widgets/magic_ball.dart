import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shake/shake.dart';
import 'package:surf_practice_magic_ball/bloc/magic_ball_bloc.dart';

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
  bool loading = false;
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
  Color targetColor = Colors.deepPurple;

  late final ShakeDetector detector;

  @override
  void initState() {
    super.initState();
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
    _idleController.animateTo(0.0).then((value) => _idleController.stop());
    _shakeController.repeat(reverse: true);
    setState(() {
      loading = true;
    });
    if (!_fadeController.isAnimating) {
      _fadeController
          .forward()
          .then((value) => context.read<MagicBallBloc>().add(Load()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTriggered,
      child: BlocListener<MagicBallBloc, MagicBallBlocState>(
        listener: (context, state) {
          if (state is MagicBallLoadingState) {
            detector.stopListening();
          } else {
            detector.startListening();
            _shakeController
                .animateTo(0)
                .then((value) => _shakeController.stop());
            _idleController.repeat(reverse: true);
            setState(() {
              loading = false;
            });
          }
          if (state is MagicBallHasDataState) {
            setState(() {
              targetColor = Colors.deepPurple;
              _fadeAnimation = ColorTween(begin: targetColor, end: Colors.black)
                  .animate(_fadeController);
            });
            _fadeController.reverse();
          }
          if (state is MagicBallHasErrorState) {
            setState(() {
              targetColor = Colors.red.shade600;
              _fadeAnimation = ColorTween(begin: targetColor, end: Colors.black)
                  .animate(_fadeController);
            });
            _fadeController.reverse();
          }
        },
        child: SlideTransition(
          position: loading ? _shakeAnimation : _idleAnimation,
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
                            gradient: RadialGradient(colors: [
                              _fadeAnimation.value ?? Colors.transparent,
                              Colors.transparent
                            ], radius: 1.5, focalRadius: 0.5),
                          ),
                          child: AnimatedBuilder(
                              animation: _opacityAnimation,
                              builder: (context, child) {
                                return Center(
                                    child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: BlocBuilder<MagicBallBloc,
                                          MagicBallBlocState>(
                                      builder: (context, state) {
                                    if (state is MagicBallHasDataState) {
                                      return Opacity(
                                        opacity: _opacityAnimation.value,
                                        child: AutoSizeText(
                                          state.data,
                                          minFontSize: 30,
                                          maxLines: 3,
                                          textAlign: TextAlign.center,
                                        ),
                                      );
                                    }
                                    if (state is MagicBallHasErrorState) {
                                      return Opacity(
                                        opacity: _opacityAnimation.value,
                                        child: AutoSizeText(
                                          state.error,
                                          minFontSize: 30,
                                          maxLines: 3,
                                          textAlign: TextAlign.center,
                                        ),
                                      );
                                    }
                                    return Opacity(
                                      opacity: _opacityAnimation.value,
                                    );
                                  }),
                                ));
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
