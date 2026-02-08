import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/app_state.dart';

class SlideViewer extends StatelessWidget {
  const SlideViewer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        // Use real slide data from session
        final session = appState.currentSession;
        final slides = session?.slides ?? [];
        final currentIndex = appState.currentSlideIndex;
        
        // Safety check
        if (slides.isEmpty) {
          return Container(
             decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
             ),
             child: Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Icon(Icons.desktop_access_disabled, size: 60, color: Colors.white24),
                   const SizedBox(height: 16),
                   Text('No slides available', style: TextStyle(color: Colors.white54)),
                 ],
               ),
             ),
          );
        }

        final currentSlide = (currentIndex < slides.length) ? slides[currentIndex] : null;

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.neonCyan.withValues(alpha: 0.2),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              // Slide Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Center(
                      child: currentSlide != null 
                        ? (currentSlide.startsWith('http') 
                            ? Image.network(
                                currentSlide,
                                fit: BoxFit.contain,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(child: CircularProgressIndicator(color: AppTheme.neonCyan));
                                },
                                errorBuilder: (context, error, stackTrace) => 
                                  const Icon(Icons.broken_image, size: 50, color: Colors.red),
                              )
                            : (currentSlide.endsWith('.pdf') 
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.picture_as_pdf, size: 64, color: Colors.red),
                                      const SizedBox(height: 16),
                                      Text(
                                        currentSlide.split('/').last,
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  )
                                : Image.asset(currentSlide, fit: BoxFit.contain, errorBuilder: (_, __, ___) => Center(child: Text(currentSlide, style: TextStyle(color: Colors.white))))
                              )
                          )
                        : const Text('End of Presentation', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
              ),
              
              // Slide Navigation
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: AppTheme.neonCyan.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios),
                      color: currentIndex > 0 ? AppTheme.neonCyan : AppTheme.textSecondary,
                      onPressed: currentIndex > 0 ? () => appState.previousSlide() : null,
                    ),
                    Text(
                      '${currentIndex + 1} / ${slides.length}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios),
                      color: currentIndex < slides.length - 1
                          ? AppTheme.neonCyan
                          : AppTheme.textSecondary,
                      onPressed: currentIndex < slides.length - 1
                          ? () => appState.nextSlide()
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
