# CheckBird Rewards & Shop System - Business Logic Document

**Document Version:** 1.0  
**Last Updated:** November 2025  
**Audience:** Product Managers, Business Stakeholders, Designers

---

## Executive Summary

The CheckBird Rewards & Shop system is a carefully designed gamification engine that motivates users to complete tasks consistently while preventing exploitation. This document explains the business logic, economy design, and anti-fraud measures in non-technical terms.

**Key Principles:**

1. **Fair Earning:** Users earn rewards through genuine productivity
2. **Anti-Farming:** Technical safeguards prevent reward exploitation
3. **Meaningful Spending:** Shop items provide real value (customization)
4. **Balanced Economy:** Earning and spending rates keep users engaged

---

## 1. The Three Currencies

### 1.1 Coins (Primary Currency)

**What are Coins?**

- The main currency users earn and spend
- Used to purchase most shop items
- Cannot be bought with real money (earn-only)
- Visible at the top of shop screen

**Why Coins?**

- Rewards genuine productivity
- Creates sense of accomplishment
- Makes shop purchases feel earned
- Drives daily engagement

**How Users Get Coins:**
| Activity | Coins Earned | Notes |
|----------|--------------|-------|
| Complete a task | 5 coins | Once per day per task |
| Complete a habit | 2 coins | Once per day per habit |
| Complete group task | +2 coins bonus | Extra reward for collaboration |
| Daily login | 5-15 coins | Increases with streak |

**Example Scenario:**

```
Alex's Monday:
- Morning: Completes "Study Math" task → +5 coins
- Afternoon: Completes "Exercise" habit → +2 coins
- Evening: Completes "Team Project" (group task) → +5 coins + 2 bonus
- Daily login (10-day streak) → +12 coins

Total earned: 26 coins in one day
```

### 1.2 Gems (Premium Currency)

**What are Gems?**

- Rare currency for special items
- Currently earned through achievements (future)
- Will be purchasable with real money (Phase 2)
- Used for charity donations in shop

**Why Gems?**

- Separate economy for premium features
- Enables charitable giving
- Future monetization path
- Makes special items feel exclusive

**Current Use:**

- Charity packs (10-20 gems)
- Future: Exclusive cosmetics
- Future: Special power-ups

**Business Strategy:**

- Phase 1: Rare rewards only
- Phase 2: IAP packs ($0.99 - $24.99)
- Phase 3: Premium subscription includes gems

### 1.3 XP (Experience Points)

**What is XP?**

- Progression metric (not a spendable currency)
- Determines user level
- Shows overall productivity
- Never decreases (always increases)

**Why XP?**

- Visible long-term progress
- Level up creates excitement
- Social status in groups
- Motivates consistency

**How Users Get XP:**
| Activity | XP Earned | Notes |
|----------|-----------|-------|
| Complete a task | 25 XP | Once per day per task |
| Complete a habit | 15 XP | Once per day per habit |
| Complete group task | +10 XP bonus | Extra reward |
| Daily login | 10-30 XP | Based on streak |

**Level System:**

```
Level 1:  0 XP (beginner)
Level 2:  100 XP (5-7 days)
Level 3:  250 XP (2 weeks)
Level 5:  1,000 XP (1 month)
Level 10: 11,000 XP (3 months)
Level 20: 35,000 XP (1 year)
```

**Why This Progression Curve?**

- Early levels fast: New users see progress quickly
- Mid levels moderate: Sustained engagement required
- High levels slow: Long-term commitment rewarded
- No cap: Always something to achieve

---

## 2. Earning Mechanics

### 2.1 Task Completion Rewards

**The Basic Rule:**

- Complete a task → Earn 5 coins + 25 XP
- Simple, predictable, fair

**The Daily Limit:**

- Each task can earn rewards **once per day**
- If you complete "Study Math" at 9 AM → Earn rewards
- If you uncomplete and recomplete at 3 PM → No additional rewards
- Next day at 9 AM → Can earn rewards again

**Why Daily Limit?**

- Prevents reward farming (spam complete/uncomplete)
- Encourages variety (do different tasks)
- Mirrors real productivity (you don't do same task 10 times/day)
- Maintains economy balance

**Example:**

```
Monday:
9:00 AM - Mark "Write Report" complete → +5 coins ✅
9:05 AM - Uncheck "Write Report" (made mistake)
9:10 AM - Re-check "Write Report" complete → No reward ❌
          (System says: "Already completed today")

Tuesday:
9:00 AM - Mark "Write Report" complete → +5 coins ✅
          (New day, new opportunity to earn)
```

### 2.2 Habit Completion Rewards

**The Basic Rule:**

- Complete a habit → Earn 2 coins + 15 XP
- Lower than tasks because habits are daily

**Why Less Than Tasks?**

- Habits are recurring (designed to be done often)
- Tasks are one-time (more effort required)
- Balance: If habits paid same, users would only do habits
- Fairness: Total daily earnings balanced

**Daily Reset:**

- Habits can be completed once per day
- Each day at midnight → Habit becomes available again
- Build streaks by completing on scheduled days

**Example:**

```
Sarah's "Meditate" habit (scheduled for Mon/Wed/Fri):

Monday: Complete → +2 coins + 15 XP ✅
Tuesday: Not scheduled (no habit to complete)
Wednesday: Complete → +2 coins + 15 XP ✅
Thursday: Not scheduled
Friday: Complete → +2 coins + 15 XP ✅

Weekly total from this habit: 6 coins + 45 XP
```

### 2.3 Group Task Bonuses

**The Bonus System:**

- Regular task in group → 5 coins + 25 XP (base)
- Group bonus → +2 coins + +10 XP (extra)
- Total → 7 coins + 35 XP

**Why Bonuses for Groups?**

- Encourages social features
- Rewards collaboration
- Makes groups valuable
- Drives team engagement

**How It Works:**

```
Tom creates task "Design Logo" in Marketing group:
1. Task appears in his personal task list
2. Task also appears in group task board
3. When Tom completes it:
   - Base reward: 5 coins + 25 XP
   - Group bonus: +2 coins + +10 XP
   - Total: 7 coins + 35 XP
4. Other group members see completion in feed
```

**Business Logic:**

- Only task creator earns rewards
- Group members see the task (visibility)
- Completing shared tasks shows accountability
- Future: Team challenges with shared rewards

### 2.4 Daily Login Rewards

**The Streak System:**

- Login every day → Build a streak
- Longer streak → Bigger rewards
- Miss a day → Streak resets to 1

**Reward Formula:**

```
Base reward: 5 coins + 10 XP (always)

Streak bonus:
- Days 1-6: No bonus
- Days 7-13: +5 coins + +10 XP (first week complete)
- Days 14-20: +10 coins + +20 XP (two weeks)
- Days 21+: +10 coins + +20 XP (continuing...)

Examples:
Day 1:  5 coins + 10 XP
Day 7:  10 coins + 20 XP (bonus kicks in!)
Day 14: 15 coins + 30 XP (bigger bonus)
Day 30: 15 coins + 30 XP (max daily login reward)
```

**Why Streaks Matter:**

- Psychological: Don't want to break the chain
- Habit formation: Daily engagement becomes routine
- Retention: Users come back daily
- Fair: Everyone starts equal, commitment rewarded

**What Breaks a Streak?**

- Not opening app for 24+ hours
- Example: Last login Monday 8 AM, next login Wednesday 9 AM → Broken

**Streak Recovery (Future):**

- One "Streak Freeze" per month (miss a day without penalty)
- Costs 50 gems to purchase extra freezes
- Encourages gem purchases

**Example Journey:**

```
Week 1 (Days 1-7):
- Daily reward: 5 coins each day
- Total: 35 coins
- Bonus unlocks on Day 7: +5 coins

Week 2 (Days 8-14):
- Daily reward: 10 coins each day (5 + 5 bonus)
- Total: 70 coins
- Day 14 unlocks next bonus

Week 3+ (Days 15+):
- Daily reward: 15 coins each day (5 + 10 bonus)
- Total per week: 105 coins
```

---

## 3. The Anti-Farming System

### 3.1 The Problem We Solved

**What is "Reward Farming"?**
Exploiting the system to earn rewards without real productivity.

**The Old Bug (Before Fix):**

```
1. User checks "Do Homework" → Earns 5 coins
2. User unchecks "Do Homework"
3. User checks again → Earns 5 MORE coins
4. Repeat 100 times → Earn 500 coins in 5 minutes
5. Buy everything in shop without doing any work

Problem: Infinite coins without productivity!
```

**Why This is Bad:**

- Ruins game economy
- Makes shop meaningless (everyone rich)
- No motivation to actually complete tasks
- Unfair to honest users
- Breaks the core value proposition

### 3.2 How We Fixed It

**The Technical Solution:**
Every task completion creates a permanent record in the database.

**What Gets Recorded:**

```
Completion Record:
- Who: User ID (e.g., "user123")
- What: Task ID (e.g., "task456")
- When: Timestamp (e.g., "2025-11-24 09:30 AM")
- Rewards: Coins earned (5), XP earned (25)
- Type: Task or Habit
```

**The Check Before Reward:**

```
User completes task → System checks database:

Query: "Did user123 complete task456 today?"

If NO records found:
  ✅ Award 5 coins + 25 XP
  ✅ Create new completion record
  ✅ Show success message

If record exists:
  ❌ Don't award anything
  ❌ Show message: "Already completed today"
```

**Why This Works:**

1. **Immutable Records:** Can't delete or change completion records
2. **Timestamp Tracking:** Knows exact time of completion
3. **Daily Reset:** "Today" is calculated server-side (can't cheat)
4. **Audit Trail:** Can review all completions for abuse detection

### 3.3 User Experience Impact

**For Honest Users (99%):**

- No impact! System feels instant
- Clear feedback on rewards earned
- Can still uncomplete tasks (mistakes happen)
- Just won't get duplicate rewards

**For Attempted Exploiters:**

- First completion: Works normally
- Second+ completion same day: Blocked with message
- No punishment (assume good faith)
- Can still use app normally

**The Message:**

```
[Toast Notification]
"Already earned rewards for this task today.
Come back tomorrow!"
```

**Why Friendly Message?**

- Assumes user made mistake (not malicious)
- Educates about daily limit
- Doesn't feel like punishment
- Encourages return tomorrow

### 3.4 Business Benefits

**Economy Protection:**

- Inflation prevented (limited coin supply)
- Shop prices remain meaningful
- Earning rates predictable
- Can plan future features confidently

**Fair Competition:**

- Leaderboards (future) will be fair
- Achievements earned legitimately
- Social credibility maintained
- Premium features valuable

**Data Integrity:**

- Accurate productivity metrics
- Trustworthy statistics
- Better insights for product decisions
- Can analyze real usage patterns

**Future Monetization:**

- IAP pricing based on real earning rates
- Premium subscriptions provide real value
- Can offer fair progression boosts
- Users trust the system

---

## 4. The Shop System

### 4.1 Shop Categories

**A. Profile Frames**

**What They Are:**
Decorative borders around your profile avatar

**Available Items:**
| Name | Price | Description |
|------|-------|-------------|
| Challenger | 10 coins | Sporty orange frame |
| Purple Dream | 5 coins | Elegant purple gradient |
| Premium Gold | 15 coins | Luxurious gold border |
| Diamond Elite | 50 coins | Prestigious diamond frame |

**Purchase Strategy:**

- Entry-level: 5-10 coins (achievable in 2-3 days)
- Mid-tier: 15 coins (about 5 days)
- Premium: 50 coins (10-14 days of consistent effort)

**Why Frames?**

- Visible in groups (social status)
- Personal expression
- Shows commitment (earned through work)
- No impact on functionality (pure cosmetic)

**B. Profile Backgrounds**

**What They Are:**
Full-width banner image at top of profile

**Available Items:**
| Name | Price | Description |
|------|-------|-------------|
| Space Explorer | 8 coins | Cosmic starfield |
| Wjbu Sunset | 10 coins | Warm orange sunset |
| Wjbu Dawn | 10 coins | Cool blue morning |
| Forest Serenity | 12 coins | Peaceful nature scene |

**Price Rationale:**

- Slightly cheaper than frames (8-12 vs 10-50)
- Still requires effort (2-4 days)
- Variety of themes (space, nature, time of day)

**Why Backgrounds?**

- Personalize profile header
- Express personality/interests
- Refresh profile look
- Complement avatar/frame choice

**C. Profile Titles**

**What They Are:**
Colored text badge displayed on profile

**Available Items:**
| Name | Price | Color | Unlock |
|------|-------|-------|--------|
| Task Master | 20 coins | Blue | Complete 50 tasks |
| Habit King | 25 coins | Green | Complete 100 habits |
| Legendary | 100 coins | Orange | Reach Level 15 |

**Special Rules:**

- Must unlock before purchase (achievement-gated)
- More expensive (aspirational goals)
- Color-coded by type
- Limited selection (exclusive feeling)

**Why Lock Titles?**

- Prevents early purchase (need to earn eligibility)
- Creates long-term goals
- Shows real accomplishment
- Can't buy credibility without work

**Business Logic:**

```
User tries to buy "Legendary" title:

Check 1: Do they have 100 coins?
  - If NO → Show "Insufficient funds"

Check 2: Are they Level 15+?
  - If NO → Show "Complete achievement first"

Check 3: Do they already own it?
  - If YES → Show "Already owned"

All checks pass → Process purchase
```

**D. Charity Packs (Gems)**

**What They Are:**
Donations to real-world causes (future integration)

**Available Items:**
| Name | Price | Cause |
|------|-------|-------|
| Books for Kids | 10 gems | Literacy programs |
| Plant a Tree | 15 gems | Reforestation |
| Feed the Hungry | 20 gems | Food banks |

**Key Difference:**

- Uses gems (not coins)
- Repeatable purchases (not one-time)
- No "owned" badge (can buy multiple times)
- Real-world impact (not cosmetic)

**Business Model (Phase 2):**

```
User purchases "Plant a Tree" for 15 gems:

If gems purchased with real money ($1.50):
- 80% ($1.20) → Actual charity donation
- 20% ($0.30) → App operational costs

User receives:
- Donation receipt (tax-deductible)
- Badge on profile (shows number donated)
- Warm feeling (made real impact)
```

**Why Charity in App?**

- Adds meaning beyond self (do good)
- Monetization that feels good
- Attracts socially conscious users
- PR/marketing value
- Tax benefits for users

### 4.2 Shop UI/UX Design

**Shop Layout:**

```
┌─────────────────────────────────────┐
│  [Avatar] Level 8  🪙 85  💎 5      │ (Header)
├─────────────────────────────────────┤
│  Frames | Backgrounds | Titles | 💝 │ (Tabs)
├─────────────────────────────────────┤
│  ┌──────┐  ┌──────┐  ┌──────┐      │
│  │ Item │  │ Item │  │ Item │      │
│  │ 🪙 10 │  │ 🪙 15 │  │OWNED │      │ (Grid)
│  └──────┘  └──────┘  └──────┘      │
│                                     │
└─────────────────────────────────────┘
```

**Key Features:**

1. **Real-time Balance:** Coin/gem counts update instantly
2. **Visual Feedback:** Owned items show green badge
3. **Tab Organization:** Easy category browsing
4. **Level Display:** Shows progression status

**Purchase Flow:**

```
1. User taps item card
   ↓
2. Confirmation dialog appears:
   "Buy Diamond Elite for 50 coins?"
   [Cancel] [Confirm]
   ↓
3. User taps Confirm
   ↓
4. Loading indicator shows
   ↓
5. System processes:
   - Check balance (50 coins available?)
   - Check ownership (already owned?)
   - Deduct coins (50 coins removed)
   - Add to inventory (item now owned)
   ↓
6. Success message:
   "Purchase successful!"
   ↓
7. UI updates:
   - Item shows "OWNED" badge
   - Coin balance: 85 → 35
   - Item now available in inventory
```

**Error Handling:**

```
Insufficient Funds:
→ "You need 50 coins but only have 35"
→ Button shows how many more needed
→ Option to go back and earn more

Already Owned:
→ "You already own this item"
→ Can't click purchase button (disabled)

Transaction Failed:
→ "Purchase failed. Please try again"
→ Coins not deducted (safe rollback)
→ Can retry immediately
```

### 4.3 Purchase Mechanics

**The Transaction System:**
All purchases use atomic transactions (all-or-nothing).

**What Happens Behind the Scenes:**

```
User buys "Premium Gold Frame" (15 coins):

Transaction Start:
├─ Step 1: Read current balance (85 coins)
├─ Step 2: Check if enough (85 >= 15) ✅
├─ Step 3: Check if owned ✅
├─ Step 4: Deduct coins (85 - 15 = 70)
├─ Step 5: Add to owned list
└─ Transaction Commit → All changes saved

If ANY step fails:
└─ Transaction Rollback → Nothing changes
```

**Why Atomic Transactions?**

- **No partial purchases:** Can't lose coins without getting item
- **No double-spending:** Can't buy two items with same coins
- **Race condition safety:** Multiple purchases at once handled correctly
- **Audit trail:** Every transaction recorded

**Real-World Example:**

```
Scenario: User has 50 coins, tries to buy two 30-coin items quickly

Without Transactions:
- Purchase 1 starts: Check balance (50) → OK
- Purchase 2 starts: Check balance (50) → OK
- Purchase 1 completes: 50 - 30 = 20 coins
- Purchase 2 completes: 20 - 30 = -10 coins ❌
- Problem: User went negative!

With Transactions:
- Purchase 1 starts: Lock balance → Check → Deduct → Release
- Purchase 2 starts: Wait for lock → Check balance (20) → Insufficient ❌
- Result: Only first purchase succeeds ✅
```

---

## 5. Economy Design Philosophy

### 5.1 Earning Rate Analysis

**Typical Active User (Daily):**

```
Morning Routine:
- 2 tasks completed: 10 coins + 50 XP
- 1 habit completed: 2 coins + 15 XP
  Subtotal: 12 coins + 65 XP

Afternoon Productivity:
- 1 task completed: 5 coins + 25 XP
- 1 group task: 7 coins + 35 XP (with bonus)
  Subtotal: 12 coins + 60 XP

Daily Login:
- 10-day streak: 10 coins + 20 XP

Total Daily: 34 coins + 145 XP
```

**Weekly Projection:**

```
7 days × 34 coins = 238 coins/week
7 days × 145 XP = 1,015 XP/week (about 1 level/week at mid-levels)
```

**Monthly Projection:**

```
30 days × 34 coins = 1,020 coins/month
30 days × 145 XP = 4,350 XP/month (about 4 levels/month)
```

### 5.2 Spending Timeline

**Purchase Roadmap:**

```
Day 1-2: Save up for first item
  → Buy "Purple Dream" frame (5 coins)
  → First customization achieved!

Day 3-5: Save for mid-tier item
  → Buy "Space Explorer" background (8 coins)
  → Profile looking unique

Day 7-10: Save for premium item
  → Buy "Diamond Elite" frame (50 coins)
  → Major achievement unlocked

Day 14-20: Save for title
  → Unlock "Task Master" achievement
  → Buy title (20 coins)
  → Full profile customization

Day 30+: Saving for legendary
  → Working toward "Legendary" title (100 coins)
  → Long-term goal maintained
```

**Why This Timeline?**

- **Quick win:** Can buy something in first week (motivation)
- **Regular rewards:** Something to save for each week
- **Long-term goals:** Premium items keep users engaged long-term
- **Progression feel:** Each purchase feels earned, not instant

### 5.3 Balance Principles

**1. Accessibility**

- Every user can afford basic items
- Entry-level items: 5-10 coins (2-3 days)
- No permanent exclusion

**2. Aspiration**

- Premium items require commitment
- Legendary title: 100 coins (3-4 weeks)
- Creates long-term goals

**3. Fairness**

- Can't buy with real money (currently)
- Everyone earns at same rate
- Skill = productivity, not wallet

**4. Meaningful**

- Prices high enough to feel earned
- Prices low enough to be achievable
- Sweet spot: 3-14 days per item

**5. Anti-Inflation**

- Daily limits prevent coin flooding
- No interest/passive income
- Supply controlled = value maintained

### 5.4 Price Sensitivity

**The Math:**

```
Average Daily Earning: 30 coins (with variance)

Item Prices:
- 5 coins = 0.16 days (instant)
- 10 coins = 0.33 days (same day)
- 15 coins = 0.5 days (next day)
- 25 coins = 0.83 days (2 days)
- 50 coins = 1.66 days (2 days)
- 100 coins = 3.33 days (4 days)

Reality Check:
Users don't earn EVERY day, so:
- 5 coins = 1-2 days actual
- 50 coins = 4-7 days actual
- 100 coins = 14-20 days actual
```

**Price Psychology:**

- **5 coins:** Impulse buy (just do it)
- **10-15 coins:** Small decision (do I want this?)
- **25-50 coins:** Medium commitment (need to save)
- **100 coins:** Major decision (really want this)

---

## 6. User Psychology & Engagement

### 6.1 Motivation Mechanics

**Variable Rewards:**

- Daily login: Amount varies with streak
- Tasks: Some give bonus (group tasks)
- Uncertainty: "How much will I earn today?"
- Dopamine: Surprise bonuses feel great

**Progress Tracking:**

- Level system: Visible advancement
- Coin balance: Growing wealth
- Shop items: Aspirational goals
- Streaks: "Don't break the chain"

**Social Proof:**

- Frames visible in groups
- Titles show achievement
- Profile customization = status
- Comparison with friends (future)

**Loss Aversion:**

- Streak breaks feel bad
- Don't want to "waste" saved coins
- Pressure to login daily
- Fear of falling behind

### 6.2 Habit Formation

**The Hook Model:**

```
1. Trigger: Notification or routine
   ↓
2. Action: Open app, complete task
   ↓
3. Reward: Coins, XP, level up
   ↓
4. Investment: Coins saved, streak maintained
   ↓
(Loop repeats daily)
```

**Why This Works:**

- **Trigger:** Daily reminder (login rewards)
- **Action:** Easy (just check a box)
- **Reward:** Immediate (coins appear instantly)
- **Investment:** Sunk cost (don't want to lose progress)

**Habit Stacking:**

```
Morning routine:
- Wake up → Check phone → Open CheckBird → See daily reward
- Becomes automatic (no willpower needed)
```

### 6.3 Retention Strategy

**Day 1-3: Onboarding**

- Goal: First purchase
- Tactic: Easy items (5-10 coins)
- Psychology: "I can do this!"

**Day 7-14: Habit Formation**

- Goal: Daily login streak
- Tactic: Increasing streak bonuses
- Psychology: "Don't break the chain"

**Day 30+: Long-term Engagement**

- Goal: Complete collection
- Tactic: Expensive aspirational items
- Psychology: "I've come this far"

**Day 90+: Mastery**

- Goal: Help others, compete
- Tactic: Groups, leaderboards (future)
- Psychology: "I'm an expert now"

---

## 7. Business Metrics & Monitoring

### 7.1 Key Performance Indicators

**Economy Health:**

```
Average Daily Coins Earned per User:
- Target: 25-35 coins
- Monitor: If too high → inflation risk
- Monitor: If too low → users frustrated

Average Days to First Purchase:
- Target: 2-4 days
- Monitor: If too high → prices too expensive
- Monitor: If too low → items too cheap

Shop Conversion Rate:
- Target: 60%+ visit shop weekly
- Target: 80%+ make purchase within 30 days
- Monitor: Engagement with shop
```

**User Engagement:**

```
Login Streak Distribution:
- Target: 40% at 7+ days
- Target: 20% at 30+ days
- Monitor: Retention indicator

Task Completion Rate:
- Target: 3+ tasks per active user per day
- Monitor: Core productivity metric

Group Task Rate:
- Target: 30% of tasks in groups
- Monitor: Social feature adoption
```

**Anti-Farming Effectiveness:**

```
Duplicate Completion Attempts:
- Track: How many users try to recomplete
- Target: <5% attempt exploit
- Action: If high, add warning message

Average Tasks per User per Day:
- Normal: 2-5 tasks
- Suspicious: 20+ tasks (investigate)
- Flag: Sudden spikes in completions
```

### 7.2 A/B Testing Opportunities

**Price Testing:**

```
Test A: "Diamond Elite" frame at 50 coins
Test B: "Diamond Elite" frame at 75 coins

Metrics:
- Purchase rate (% who buy)
- Days to purchase (how long to save)
- User satisfaction (surveys)

Decision: Choose price with highest engagement + satisfaction
```

**Reward Testing:**

```
Test A: Tasks worth 5 coins
Test B: Tasks worth 7 coins

Metrics:
- Task completion rate
- Daily active users
- Time to first shop purchase

Risk: Higher rewards = faster inflation
```

**UI Testing:**

```
Test A: Shop with tabs (current)
Test B: Shop with filters/search

Metrics:
- Purchase conversion
- Time in shop
- Items viewed per session
```

### 7.3 Red Flags to Monitor

**Economy Breaking:**

- Average coins/user grows >10%/month (inflation)
- Shop purchases decline (items not desirable)
- Users stockpile coins (nothing to buy)

**Farming Attempts:**

- Sudden spikes in completions per user
- Same task completed many times same day
- Abnormal coin growth rates

**User Frustration:**

- Shop visits but no purchases (too expensive?)
- Login streaks break frequently (not engaging?)
- Task completion rates decline (no motivation?)

**Technical Issues:**

- Purchase failures increase (transaction problems)
- Balance inconsistencies (sync issues)
- Duplicate items appearing (database errors)

---

## 8. Future Enhancements

### 8.1 Phase 2: Monetization (Q2 2026)

**Gem Purchases:**

```
Gem Packs (In-App Purchase):
- Starter: 10 gems → $0.99
- Popular: 50 gems → $3.99 (20% bonus)
- Value: 100 gems → $6.99 (40% bonus)
- Ultimate: 500 gems → $24.99 (67% bonus)

Strategy:
- First purchase discount (50% off starter)
- Limited-time offers (holidays)
- Reward for reviews (5 free gems)
```

**Premium Subscription: "CheckBird Pro" ($4.99/month)**

```
Benefits:
- 2x coins and XP from all activities
- Exclusive shop items (Pro frames/backgrounds)
- Ad-free experience (when ads added)
- Cloud backup (restore progress)
- Advanced analytics (productivity insights)
- Priority support

Why Users Buy:
- Value: Pays for itself in time saved
- Exclusivity: Unique cosmetics
- Convenience: Faster progression
- Support: Help app development
```

**ROI Calculation:**

```
Free user earnings: 30 coins/day × 30 days = 900 coins/month
Pro user earnings: 60 coins/day × 30 days = 1,800 coins/month

Extra purchasing power: +900 coins
Price: $4.99
Value per coin: $0.0055

Is it worth it?
- For casual users: No (can earn free)
- For power users: Yes (time savings)
- For supporters: Yes (want to support app)
```

### 8.2 Phase 3: Advanced Shop (Q3 2026)

**New Categories:**

```
Animations:
- Confetti on task completion: 30 coins
- Sparkle effect on level up: 50 coins
- Custom notification sounds: 25 coins

Power-Ups:
- 2x Coins (24 hours): 50 gems
- Streak Freeze (1 day): 20 gems
- XP Boost (1 week): 75 gems

Bundles:
- Starter Pack: Frame + Background + Title → 40 coins (save 5)
- Premium Pack: All frames + All backgrounds → 100 coins (save 20)
- Ultimate Pack: Everything → 200 coins (save 50)
```

**Limited Editions:**

```
Seasonal Items:
- Halloween: Spooky frame (October only)
- Christmas: Festive background (December)
- Back-to-School: Academic title (August-September)

Strategy:
- Creates urgency (FOMO)
- Rewards loyal users
- Encourages spending
- Generates excitement
```

### 8.3 Phase 4: Social Economy (Q4 2026)

**Gift System:**

```
Send Gifts to Friends:
- Transfer coins (max 10/day)
- Gift shop items
- Send gems (purchased only)

Use Cases:
- Thank friend for help
- Birthday gifts
- Group rewards
- Charity within community

Limits:
- Prevent farming (can't gift yourself)
- Daily caps (prevent coin selling)
- Only to friends (no strangers)
```

**Group Economy:**

```
Group Fund:
- Members contribute coins
- Unlock group cosmetics
- Shared group avatar frames
- Group achievements

Benefits:
- Team building
- Shared goals
- Collective rewards
- Social pressure (contribute!)
```

**Trading System (Controversial):**

```
Swap Items:
- Trade frames for backgrounds
- Exchange with friends
- Marketplace for rare items

Concerns:
- Creates secondary market
- Potential for scams
- Hard to moderate
- May need real-money integration

Decision: Probably not implement (too complex)
```

---

## 9. Competitive Advantages

### Our Unique Approach

**vs. Habitica (Complex RPG)**

- **Their approach:** Full RPG with health, equipment, battles
- **Our approach:** Simplified rewards (just coins/XP)
- **Advantage:** Easier to understand, less overwhelming

**vs. Todoist (No Rewards)**

- **Their approach:** "Karma" points (meaningless)
- **Our approach:** Coins that buy real features
- **Advantage:** Tangible rewards, actual motivation

**vs. Forest (Single Mechanic)**

- **Their approach:** Plant trees only
- **Our approach:** Multiple currencies, shop, levels
- **Advantage:** More variety, longer engagement

**vs. Any.do (Basic Completion)**

- **Their approach:** Checkboxes only
- **Our approach:** Rewards, streaks, progression
- **Advantage:** Gamification without complexity

**Our Sweet Spot:**

```
Simple enough: Like traditional to-do apps
Engaging enough: Like game apps
Fair enough: Anti-farming protection
Social enough: Groups and collaboration
Monetizable: Premium features without pay-to-win
```

---

## 10. Success Criteria

### How We Know It's Working

**User Engagement:**

- ✅ 60% daily active user rate
- ✅ Average 7+ day login streaks
- ✅ 3+ tasks completed per user per day
- ✅ 80% visit shop within first week

**Economy Health:**

- ✅ <1% exploit attempts
- ✅ Stable earning rate (25-35 coins/day)
- ✅ 70%+ make first purchase within 14 days
- ✅ Regular purchases (not just one-time)

**Business Metrics:**

- ✅ Month-over-month user growth
- ✅ Low churn rate (<30% monthly)
- ✅ High retention (40%+ day 30)
- ✅ Positive reviews (4.5+ stars)

**Monetization (Phase 2):**

- ✅ 5% free-to-paid conversion
- ✅ $1.50+ ARPU (average revenue per user)
- ✅ Positive user sentiment on pricing
- ✅ Subscription renewal rate >60%

---

## Conclusion

The CheckBird Rewards & Shop system is built on three pillars:

1. **Fair Earning:** Users genuinely earn rewards through productivity
2. **Smart Protection:** Anti-farming ensures economy stability
3. **Meaningful Spending:** Shop items provide real value

This creates a sustainable engagement loop:

- Complete tasks → Earn rewards → See progress → Want more → Come back tomorrow

The system is:

- ✅ Fair (no pay-to-win)
- ✅ Balanced (earning = spending rates)
- ✅ Protected (anti-exploit measures)
- ✅ Engaging (daily motivation)
- ✅ Scalable (ready for monetization)

**Most importantly:** It makes productivity fun without feeling manipulative.

---

**Next Steps:**

1. Monitor economy metrics (see section 7.1)
2. Gather user feedback on prices
3. Plan Phase 2 monetization (see section 8.1)
4. Test new shop items (limited editions)
5. Expand anti-farming if needed

**Questions or Feedback:**
Contact: product@checkbird.app

---
