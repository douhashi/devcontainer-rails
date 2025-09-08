# MusicGeneration Model Migration Strategy

## Overview

This document outlines the migration strategy for introducing the MusicGeneration model to manage KIE API generation units more efficiently.

## Background

Previously, the system created one Track per API call. Since the KIE API returns 2 tracks per call in the `sunoData` array, we were not fully utilizing the API response. The MusicGeneration model was introduced to:

1. Reduce API calls by 50%
2. Better organize the relationship between API calls and generated tracks
3. Improve error handling and retry logic

## Architecture Changes

### Before (Old Architecture)
```
Content → Track (1 API call = 1 Track, wasting the 2nd track)
```

### After (New Architecture)
```
Content → MusicGeneration → Track (1 API call = 1 MusicGeneration = 2 Tracks)
```

## Migration Phases

### Phase 1: Backward Compatibility (Current)
- **Status**: ✅ Completed
- **Timeline**: Immediate upon deployment
- **Changes**:
  - MusicGeneration model introduced
  - `music_generation_id` is optional on Track model
  - Existing Tracks continue to work without MusicGeneration
  - New Tracks are created through MusicGeneration

### Phase 2: Data Migration
- **Status**: 🔄 In Progress
- **Timeline**: 1-2 weeks after deployment
- **Changes**:
  - Create placeholder MusicGenerations for existing Tracks
  - Link existing Tracks to their MusicGenerations
  - Ensure all Tracks have a `music_generation_id`

```ruby
# Migration script example
Track.where(music_generation_id: nil).find_each do |track|
  music_generation = MusicGeneration.create!(
    content: track.content,
    task_id: track.metadata['task_id'] || "legacy_#{SecureRandom.hex(16)}",
    status: track.status,
    prompt: track.content.audio_prompt,
    generation_model: track.metadata['model_name'] || 'chirp-v3-5',
    api_response: { legacy: true }
  )
  track.update!(music_generation_id: music_generation.id)
end
```

### Phase 3: Deprecation Notice
- **Status**: 📅 Planned
- **Timeline**: 1 month after deployment
- **Changes**:
  - Add deprecation warnings to TracksController#create
  - Update documentation to use MusicGenerationQueueingService
  - Notify frontend team about the changes

### Phase 4: Make music_generation_id Required
- **Status**: 📅 Planned
- **Timeline**: 2 months after deployment
- **Changes**:
  - Remove `optional: true` from Track's music_generation association
  - Add database constraint: `NOT NULL` on `tracks.music_generation_id`
  - Remove legacy Track creation code

```ruby
# Migration to add NOT NULL constraint
class MakeMusicGenerationIdRequired < ActiveRecord::Migration[8.0]
  def change
    change_column_null :tracks, :music_generation_id, false
  end
end
```

### Phase 5: Cleanup
- **Status**: 📅 Planned
- **Timeline**: 3 months after deployment
- **Changes**:
  - Remove GenerateTrackJob (replaced by GenerateMusicGenerationJob)
  - Remove TrackQueueingService (replaced by MusicGenerationQueueingService)
  - Clean up deprecated controller actions
  - Update all tests to use new models

## Rollback Plan

If issues arise during migration:

1. **Phase 1-2**: Can safely rollback by:
   - Keeping `music_generation_id` optional
   - Continuing to use both old and new creation paths

2. **Phase 3-4**: More complex rollback:
   - Would need to restore old job classes
   - May need to unlink Tracks from MusicGenerations
   - Database backup recommended before Phase 4

## Monitoring

Key metrics to track during migration:

1. **API Call Reduction**: Should see ~50% reduction in KIE API calls
2. **Error Rates**: Monitor for any increase in generation failures
3. **Performance**: Track generation time and success rates
4. **Data Integrity**: Ensure all Tracks maintain their audio files and metadata

## Benefits After Migration

1. **Efficiency**: 50% reduction in API calls
2. **Cost Savings**: Lower API usage costs
3. **Better Organization**: Clear relationship between API calls and tracks
4. **Improved Debugging**: Easier to trace issues with generation units
5. **Future Flexibility**: Foundation for batch processing and other optimizations

## Contact

For questions or issues during migration:
- Technical Lead: [Your Name]
- Migration Status: Check `#migration-status` channel
- Issues: Report to GitHub Issues with label `migration`