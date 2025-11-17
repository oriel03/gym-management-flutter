import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import 'package:gym_management_app/components/component_form.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentIndex = 0;

  // Lista de imágenes del gym optimizada (URLs con menor resolución para mejor rendimiento)
  final List<String> _gymImages = [
    'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
    'https://images.unsplash.com/photo-1549060279-7e168fcee0c2?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
  ];

  @override
  void initState() {
    super.initState();
    _startImageSlider(); // Activado para mostrar el slider
  }

  void _startImageSlider() {
    _timer = Timer.periodic(Duration(seconds: 4), (timer) {
      if (!mounted) return; // Verificación de seguridad

      if (_currentIndex < _gymImages.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentIndex,
          duration: Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Activado para evitar memory leaks
    _pageController.dispose(); // Activado para liberar recursos
    super.dispose();
  }

  // Widget optimizado para mostrar imágenes de red
  Widget _buildOptimizedImage(
    String imageUrl, {
    double? width,
    double? height,
  }) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover, //como se ajusta la imagen
      memCacheWidth: width != null
          ? (width * 0.8).round()
          : null, // Optimización de memoria
      memCacheHeight: height != null ? (height * 0.8).round() : null,
      /*
      OPTIMIZACION DE MEMORIA
      lo multiplica por 0.8 para que la imagen quede optimizada, usando 36% de la memoria, comprime la foto
      pero no la calidad.
      */

      //Mientras la imagen carga
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
          ),
        ),
      ),

      //Las transcisiones
      fadeInDuration: Duration(milliseconds: 300),
      filterQuality: FilterQuality.medium,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            // Contenido principal (fondo) - Ahora con slider de imágenes optimizado
            Container(
              width: double.infinity,
              height: double.infinity,
              child: Stack(
                children: [
                  // Slider de imágenes de fondo
                  PageView.builder(
                    controller: _pageController,
                    itemCount: _gymImages.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return _buildOptimizedImage(
                        _gymImages[index],
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height,
                      );
                    },
                  ),
                  // Overlay con gradiente
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color.fromRGBO(
                            44,
                            50,
                            50,
                            1,
                          ), // Más transparente para mostrar imágenes
                          Color.fromRGBO(218, 165, 32, 0.6),
                        ],
                      ),
                    ),
                  ),
                  // Indicadores del slider
                  Positioned(
                    bottom: 100,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _gymImages.asMap().entries.map((entry) {
                        return Container(
                          width: 8,
                          height: 8,
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentIndex == entry.key
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Navbar flotante
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                height: 70,
                padding: EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Color.fromRGBO(44, 50, 50, 0.9),
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo/Título
                    Text(
                      'VALHALLA GYM',
                      style: TextStyle(
                        color: Color.fromRGBO(243, 243, 243, 1.0),
                        fontSize: 24,
                        fontFamily: 'Nordic chance',
                        fontWeight: FontWeight.normal,
                      ),
                    ),

                    // Botones
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.min,
                      children: [],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 110,
              left: 16,
              right: 16,
              bottom: 16,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 800) {
                    return Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: ComponentForm(),
                          ),
                        ),
                      ],
                    );
                  }
                  // CORREGIDO: EdgeInsets.all() en lugar de EdgeInsetsGeometry.all()
                  return Padding(
                    padding: EdgeInsets.all(20),
                    child: ComponentForm(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
