/// Configuration for mapping stories to their specific cover images
class StoryCoverImages {
  static const Map<String, String> _storyCoverMap = {
    // Boys Smile Story
    'boys-smile': 'https://miplbkihtavbnxgznudj.supabase.co/storage/v1/object/public/product-media/products/new/boycover.png',
    'boys smile': 'https://miplbkihtavbnxgznudj.supabase.co/storage/v1/object/public/product-media/products/new/boycover.png',
    'boy smile': 'https://miplbkihtavbnxgznudj.supabase.co/storage/v1/object/public/product-media/products/new/boycover.png',
    
    // Girl Counts with Forest Friends
    'girl-counts': 'https://miplbkihtavbnxgznudj.supabase.co/storage/v1/object/public/product-media/products/new/girl1.png',
    'girl counts': 'https://miplbkihtavbnxgznudj.supabase.co/storage/v1/object/public/product-media/products/new/girl1.png',
    'forest friends': 'https://miplbkihtavbnxgznudj.supabase.co/storage/v1/object/public/product-media/products/new/girl1.png',
    'girl counts with forest friends': 'https://miplbkihtavbnxgznudj.supabase.co/storage/v1/object/public/product-media/products/new/girl1.png',
    
    // Boy The Dinos Need You
    'dinos-need-you': 'https://miplbkihtavbnxgznudj.supabase.co/storage/v1/object/public/product-media/products/new/image-thumb.jpeg',
    'dinos need you': 'https://miplbkihtavbnxgznudj.supabase.co/storage/v1/object/public/product-media/products/new/image-thumb.jpeg',
    'dinosaur': 'https://miplbkihtavbnxgznudj.supabase.co/storage/v1/object/public/product-media/products/new/image-thumb.jpeg',
    'dinos': 'https://miplbkihtavbnxgznudj.supabase.co/storage/v1/object/public/product-media/products/new/image-thumb.jpeg',
    'the dinos need you': 'https://miplbkihtavbnxgznudj.supabase.co/storage/v1/object/public/product-media/products/new/image-thumb.jpeg',
  };

  /// Default cover image for stories not in the map
  static const String defaultCoverImage = 'https://miplbkihtavbnxgznudj.supabase.co/storage/v1/object/public/product-media/products/new/cover-image.png';

  /// Get the cover image URL for a specific story
  /// 
  /// [bookName] - The name of the book/story
  /// [bookId] - The ID of the book/story
  /// 
  /// Returns the appropriate cover image URL
  static String getCoverImage(String bookName, String bookId) {
    final normalizedName = bookName.toLowerCase().trim();
    final normalizedId = bookId.toLowerCase().trim();
    
    // First try to match by exact ID
    if (_storyCoverMap.containsKey(normalizedId)) {
      return _storyCoverMap[normalizedId]!;
    }
    
    // Then try to match by name
    if (_storyCoverMap.containsKey(normalizedName)) {
      return _storyCoverMap[normalizedName]!;
    }
    
    // Try partial name matching
    for (final entry in _storyCoverMap.entries) {
      if (normalizedName.contains(entry.key) || entry.key.contains(normalizedName)) {
        return entry.value;
      }
    }
    
    // Return default if no match found
    return defaultCoverImage;
  }

  /// Get all available story mappings (for debugging)
  static Map<String, String> getAllMappings() {
    return Map.from(_storyCoverMap);
  }

  /// Add a new story mapping (for future stories)
  static void addMapping(String key, String coverImageUrl) {
    _storyCoverMap[key.toLowerCase()] = coverImageUrl;
  }
}
