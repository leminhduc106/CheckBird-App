# CheckBird Rewards & Shop System - Complete Implementation

## Overview

This document describes the comprehensive rewards and shop system implemented for CheckBird, designed to prevent reward farming, encourage consistent usage, and provide a fair in-app economy.

## System Architecture

### Core Models

#### 1. **UserRewards** (`lib/models/reward/user_rewards.dart`)

Stores user's reward statistics in Firestore:

- **Currencies**: Coins (earned), Gems (premium)
- **Progression**: XP and calculated Level (exponential curve)
- **Statistics**: Total tasks/habits completed
- **Streaks**: Daily login tracking
- **Level System**:
  - Level 1-10: Fixed XP thresholds (100, 250, 500, 1000, 2000, 3500, 5500, 8000, 11000, 15000)
  - Level 11+: +2000 XP per level
  - Real-time level calculation from XP

#### 2. **TaskCompletionRecord** (`lib/models/reward/task_completion_record.dart`)

Immutable completion history stored in Firestore:

- Tracks: taskId, userId, timestamp, rewards earned
- **Purpose**: Prevents reward farming by recording each unique completion
- **Validation**: Checks if task already completed today before awarding rewards

#### 3. **ShopItem** (`lib/models/shop/shop_item.dart`)

Base class for all purchasable items:

- **FrameItem**: Profile frames (5-50 coins)
- **BackgroundItem**: Profile backgrounds (8-12 coins)
- **TitleItem**: Profile titles with colors (20-100 coins)
- **CharityPackItem**: Donation items (10-20 gems, repeatable)

### Core Services

#### **RewardsService** (`lib/services/rewards_service.dart`)

Central rewards management with Firestore backend:

**Key Features:**

- ✅ **Anti-Farming Protection**: `canEarnRewardsForTask()` validates completion eligibility
- ✅ **Atomic Transactions**: All currency operations use Firestore transactions
- ✅ **Task vs Habit Logic**:
  - **Tasks**: 5 coins + 25 XP (one-time per day)
  - **Habits**: 2 coins + 15 XP (daily repeatable)
  - **Group Bonus**: +2 coins, +10 XP
- ✅ **Daily Login Rewards**: Streak-based bonuses (5-10+ coins, 10-20+ XP)
- ✅ **Real-time Streams**: `getUserRewardsStream()` for live UI updates

**Methods:**

```dart
// Validate completion eligibility
Future<bool> canEarnRewardsForTask({taskId, userId, taskType})

// Award rewards for task completion (with anti-farming)
Future<Map<String, int>?> awardTaskCompletionRewards({...})

// Currency operations (transaction-safe)
Future<bool> spendCoins({userId, amount})
Future<bool> spendGems({userId, amount})
Future<void> addCoins({userId, amount})
Future<void> addGems({userId, amount})

// Daily login streak tracking
Future<Map<String, dynamic>?> checkDailyLogin(userId)

// Completion history
Future<List<TaskCompletionRecord>> getCompletionHistory({userId, limit})
```

#### **ShopController** (`lib/services/shop_controller.dart`)

Manages shop inventory and purchases:

**Features:**

- ✅ **Purchase Validation**: Checks funds + ownership before purchase
- ✅ **Transaction Safety**: Spend currency → Add to inventory (atomic)
- ✅ **Item Catalog**: Frames (4 items), Backgrounds (4 items), Titles (3 items), Charity (3 items)
- ✅ **Inventory Check**: Prevents duplicate purchases (except charity)

**Methods:**

```dart
// Get item catalogs
List<FrameItem> getAvailableFrames()
List<BackgroundItem> getAvailableBackgrounds()
List<TitleItem> getAvailableTitles()
List<CharityPackItem> getCharityPacks()

// Purchase flow
Future<bool> purchaseItem({userId, item})
Future<bool> canAfford({userId, item})
```

### UI Components

#### **ShopScreen** (`lib/screens/shop/shop_screen.dart`)

Complete shop redesign with 4 tabs:

**Features:**

- ✅ **Real-time Currency Display**: StreamBuilder shows live coins/gems/level
- ✅ **Tabbed Navigation**: Frames | Backgrounds | Titles | Charity
- ✅ **Ownership Indicators**: "OWNED" badge on purchased items
- ✅ **Purchase Flow**: Confirmation dialog → Loading → Success/Error feedback
- ✅ **Beautiful UI**: Gradient headers, shadows, color-coded currency

**State Management:**

- UserProfile loaded for inventory checking
- RewardsService stream for real-time balance updates
- Loading states for async operations

#### **DailyRewardDialog** (`lib/widgets/rewards/daily_reward_dialog.dart`)

Daily login reward popup:

**Features:**

- ✅ **Streak Display**: Fire icon + day count
- ✅ **Reward Breakdown**: Coins + XP earned
- ✅ **Motivational Messages**: Different messages based on streak length
- ✅ **Auto-show**: Triggered on HomeScreen mount via `addPostFrameCallback`

**Behavior:**

- Only shows once per day (checked via `checkDailyLogin`)
- Non-dismissible until user clicks "Let's Go!"
- Streak breaks if user misses a day

#### **TodoItem** (`lib/screens/task/widgets/todo_item.dart`)

Updated task completion handler:

**Changes:**

- ✅ **Anti-Farming Logic**: Calls `awardTaskCompletionRewards()` which validates before awarding
- ✅ **User Feedback**: Shows earned coins + XP, or "Already completed today" message
- ✅ **Error Handling**: Graceful degradation if user not authenticated

## Reward Economy Design

### Earning Rates

| Action               | Coins   | XP       | Notes                           |
| -------------------- | ------- | -------- | ------------------------------- |
| Complete Task        | 5       | 25       | Once per day per task           |
| Complete Habit       | 2       | 15       | Once per day (habits are daily) |
| Group Task Bonus     | +2      | +10      | Additional reward               |
| Daily Login (Base)   | 5       | 10       | Increases with streak           |
| Daily Login (Streak) | +5/week | +10/week | Bonus per 7-day streak          |

### Shop Prices

| Category      | Price Range  | Currency |
| ------------- | ------------ | -------- |
| Frames        | 5-50 coins   | Coins    |
| Backgrounds   | 8-12 coins   | Coins    |
| Titles        | 20-100 coins | Coins    |
| Charity Packs | 10-20 gems   | Gems     |

### Balance Philosophy

- **Earning**: ~15-25 coins/day (3-5 tasks, or daily habit streak + login)
- **First Purchase**: Can buy cheapest item (5 coins) in 1 day
- **Premium Items**: Require 2-10 days of consistent usage
- **Gems**: Premium currency (future: IAP or special achievements)

## Anti-Farming Mechanisms

### Problem Solved

**Before**: User could toggle task complete/incomplete infinitely for infinite coins.

**Solution**: `TaskCompletionRecord` in Firestore tracks each completion:

1. **Task Completion Flow**:

   ```
   User marks task complete
   → Check: Does TaskCompletionRecord exist for this taskId + today?
   → If YES: Show "Already completed today", no rewards
   → If NO: Award rewards + Create TaskCompletionRecord
   ```

2. **Habit Completion Flow**:

   ```
   User marks habit complete
   → Check: Does TaskCompletionRecord exist for this taskId + today?
   → If YES: Mark complete visually, no rewards
   → If NO: Award rewards + Create TaskCompletionRecord
   ```

3. **Uncomplete Action**:
   ```
   User marks task incomplete
   → Remove visual completion (lastCompleted = null)
   → TaskCompletionRecord stays in Firestore (immutable audit trail)
   → Re-completing won't award rewards again (already have record for today)
   ```

### Firestore Transaction Safety

All currency operations use `runTransaction()`:

```dart
await _firestore.runTransaction((transaction) async {
  final snapshot = await transaction.get(userDoc);
  // Validate current balance
  if (current.coins < price) return false;
  // Update atomically
  transaction.update(userDoc, {'coins': current.coins - price});
  return true;
});
```

**Benefits**:

- ✅ No race conditions
- ✅ No negative balances
- ✅ Concurrent-safe purchases

## Database Schema

### Firestore Collections

#### `userRewards/{userId}`

```json
{
  "coins": 125,
  "gems": 0,
  "xp": 850,
  "level": 4,
  "totalTasksCompleted": 34,
  "totalHabitsCompleted": 12,
  "lastLoginDate": Timestamp,
  "currentLoginStreak": 7,
  "longestLoginStreak": 12,
  "lastRewardEarnedAt": Timestamp
}
```

#### `taskCompletions/{completionId}`

```json
{
  "userId": "abc123",
  "taskId": "task_xyz",
  "taskName": "Morning workout",
  "completedAt": Timestamp,
  "coinsEarned": 5,
  "xpEarned": 25,
  "isHabit": false
}
```

#### `userProfiles/{userId}` (existing, extended)

```json
{
  "username": "john_doe",
  "ownedFrames": ["challenger", "purple"],
  "ownedBackgrounds": ["space"],
  "ownedTitles": ["default", "taskmaster"],
  "selectedFrameId": "challenger",
  "selectedBackgroundId": "space",
  "selectedTitleId": "taskmaster"
}
```

## Testing Checklist

### Reward Earning

- [ ] Complete a task → Earn 5 coins + 25 XP
- [ ] Complete same task again today → Show "Already completed" message, no coins
- [ ] Uncomplete and recomplete task → No additional coins
- [ ] Complete habit → Earn 2 coins + 15 XP
- [ ] Complete same habit again today → Show "Already completed" message
- [ ] Next day: Complete same task/habit → Earn coins again (new day)
- [ ] Group task completion → Earn bonus (+2 coins, +10 XP)

### Shop Functionality

- [ ] View shop → All items display with correct prices
- [ ] Purchase item with sufficient funds → Success, inventory updated
- [ ] Purchase item with insufficient funds → Error message
- [ ] Purchase owned item → Button shows "OWNED", can't repurchase
- [ ] Purchase charity pack → Success, can purchase again (repeatable)
- [ ] Real-time balance updates after purchase
- [ ] Tab navigation works between categories

### Daily Login Rewards

- [ ] First login today → Daily reward dialog shows
- [ ] Second visit today → Dialog doesn't show again
- [ ] Login next day (consecutive) → Streak increments, higher rewards
- [ ] Miss a day, login again → Streak resets to 1
- [ ] 7-day streak → See increased bonus rewards

### Edge Cases

- [ ] Multiple tasks completed in rapid succession → All award correctly
- [ ] Concurrent purchases → Only one succeeds if funds insufficient
- [ ] Network error during purchase → Graceful error, no funds lost
- [ ] User signs out and back in → Rewards persist
- [ ] Level up → UI shows new level immediately

## Future Enhancements

### Phase 2: Achievements

- [ ] First Task: Complete 1 task (5 gems)
- [ ] Task Master: Complete 50 tasks (20 coins)
- [ ] Habit Streak: 30-day habit streak (50 coins)
- [ ] Shop Enthusiast: Purchase 5 items (10 gems)
- [ ] Level 10: Reach level 10 (25 coins)

### Phase 3: Weekly Quests

- [ ] "Complete 7 tasks this week" → 30 coins
- [ ] "Login 7 days straight" → 15 gems
- [ ] "Complete all habits for 3 days" → 20 coins

### Phase 4: Premium Currency

- [ ] In-app purchases for gems
- [ ] Watch ads for bonus coins
- [ ] Referral rewards

## Migration Guide

### For Existing Users

Old `RewardsController` (SharedPreferences) → New `RewardsService` (Firestore):

**Migration Script** (to run once):

```dart
Future<void> migrateRewards(String userId) async {
  final prefs = await SharedPreferences.getInstance();
  final oldCoins = prefs.getInt('user_coins') ?? 0;

  if (oldCoins > 0) {
    await RewardsService().addCoins(userId: userId, amount: oldCoins);
    await prefs.remove('user_coins'); // Clean up old data
  }
}
```

**Note**: TaskCompletionRecords don't exist for old completions, so users start fresh with anti-farming protection.

## Summary

**Problem Fixed**: ✅ Infinite coin farming from task toggle  
**New Features**: ✅ XP/Levels, Daily Rewards, Proper Shop, Real-time Updates  
**Architecture**: ✅ Firestore backend, Transaction-safe, Scalable  
**User Experience**: ✅ Clear feedback, Motivational UI, Fair economy

**Key Files**:

- `lib/models/reward/` - Data models
- `lib/services/rewards_service.dart` - Core reward logic
- `lib/services/shop_controller.dart` - Shop management
- `lib/screens/shop/shop_screen.dart` - Shop UI
- `lib/widgets/rewards/daily_reward_dialog.dart` - Daily rewards
- `lib/screens/task/widgets/todo_item.dart` - Task completion with anti-farming

All systems operational and ready for testing! 🎉
