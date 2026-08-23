import 'package:flutter/material.dart';
import 'package:meeras_fest_app/admin/providers/curosel_provider.dart';
import 'package:provider/provider.dart';



/// Admin-side carousel manager: pick, upload (with compression handled in
/// the provider), and delete the images shown on the home page carousel.
class CarouselSection extends StatelessWidget {
  const CarouselSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CarouselProvider>(
      builder: (context, carouselPro, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Home Carousel",
                    style: TextStyle(
                        color: Color(0xff1F2937),
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                  TextButton.icon(
                    onPressed: carouselPro.isUploading
                        ? null
                        : () => carouselPro.pickAndUploadImages(),
                    icon: const Icon(Icons.add_photo_alternate_rounded,
                        size: 18, color: Color(0xff6366F1)),
                    label: const Text(
                      "Add Image",
                      style: TextStyle(
                          color: Color(0xff6366F1),
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (carouselPro.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    carouselPro.errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              if (carouselPro.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (carouselPro.images.isEmpty &&
                  carouselPro.uploadProgress.isEmpty)
                _EmptyState(onTap: () => carouselPro.pickAndUploadImages())
              else
                SizedBox(
                  height: 110,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ...carouselPro.images
                          .map((image) => _CarouselTile(image: image)),
                      ...carouselPro.uploadProgress.values
                          .map((progress) => _UploadingTile(progress: progress)),
                      _AddTile(
                        isUploading: carouselPro.isUploading,
                        onTap: () => carouselPro.pickAndUploadImages(),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 90,
        decoration: BoxDecoration(
          color: const Color(0xffF9FAFB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xffE5E7EB)),
        ),
        child: const Center(
          child: Text(
            "No carousel images yet — tap to add",
            style: TextStyle(color: Color(0xff9CA3AF), fontSize: 12),
          ),
        ),
      ),
    );
  }
}

class _CarouselTile extends StatelessWidget {
  const _CarouselTile({required this.image});
  final CarouselImageModel image;

  @override
  Widget build(BuildContext context) {
    final carouselPro = context.read<CarouselProvider>();
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              image.imageUrl,
              width: 110,
              height: 110,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  width: 110,
                  height: 110,
                  color: const Color(0xffF3F4F6),
                  child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                );
              },
              errorBuilder: (context, error, stack) => Container(
                width: 110,
                height: 110,
                color: const Color(0xffF3F4F6),
                child: const Icon(Icons.broken_image_rounded,
                    color: Color(0xff9CA3AF)),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _confirmDelete(context, carouselPro, image),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, CarouselProvider provider, CarouselImageModel image) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Remove image?"),
        content: const Text(
            "This removes it from the carousel and deletes it from storage."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              provider.deleteImage(image);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _UploadingTile extends StatelessWidget {
  const _UploadingTile({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          color: const Color(0xffF3F4F6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            value: progress > 0 ? progress : null,
          ),
        ),
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.isUploading, required this.onTap});
  final bool isUploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          color: const Color(0xffF9FAFB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xffD1D5DB), width: 1.4),
        ),
        child: const Center(
          child: Icon(Icons.add_rounded, color: Color(0xff9CA3AF), size: 28),
        ),
      ),
    );
  }
}