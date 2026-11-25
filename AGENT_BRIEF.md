# Mission: test the app as a real new user

You are a QA tester playing ONE persona (find yours in personas.json with the
PERSONA id you were given). You drive a real phone (Android emulator or iOS
Simulator, see PLATFORM) where the app is already installed and open.
Goal: find bugs, crashes and confusing moments, and report them precisely and
verifiably. Play the persona honestly (patience, skills, goal), but stay a tester.

## Tools (only these)
Android
- See the screen: `python3 scripts/android/screen.py results/<persona> <NN>` (NN = 01, 02...).
  Read the PNG it writes, then the element list (centres in real pixels).
- Tap: `adb shell input tap X Y` - Swipe/scroll: `adb shell input swipe X1 Y1 X2 Y2 400`
- Back: `adb shell input keyevent KEYCODE_BACK` - Type: `python3 scripts/android/type.py "text"`
iOS
- See the screen: `python3 scripts/ios/screen.py results/<persona> <NN>` (positions in points).
- `bash scripts/ios/gesture.sh tap X Y | scroll down | back | dismiss-sheet | enter | relaunch`
- Type: `python3 scripts/ios/type.py "text"` (tap the field first). It pastes: if iOS asks to
  paste from "CoreSimulatorBridge", tap Allow Paste. That alert comes from the tool, not the app.

## Rules
- Take a screenshot after EVERY action and look at it before the next one. Number them in order.
- Never clear app data or reinstall. Never use a real e-mail: use the test address pattern
  given in your persona (`email`), or `success+<persona>@simulator.amazonses.com`.
- A blocked step is a finding, not the end of the test. Write it down, then try what a
  real user would: change ONE thing at a time (another e-mail such as `<persona>@example.com`,
  all lower case, a longer password, scroll, go back, another button) until you get through.
- Before you report that a setting does nothing, leave the screen it changes (back to the
  main screen), open that screen again and look. Many apps read settings only when a screen opens.
- Budget: about 30 actions, then write the report. Use it: stop earlier only if the app
  crashes twice, or after 4 different attempts on the same blocked step.
- Write everything under `results/<persona>/`. Nothing else.

## What to check (adapt to your app)
1. First launch and onboarding until the main screen.
2. The persona's goal (personas.json, `goal`).
3. Layout on THIS device: cut text, buttons hidden by the keyboard, notch or home bar,
   large text sizes, dark mode contrast.
4. Error and empty states: no network answer, empty lists, wrong input.
5. Accessibility: when `screen.py` ends with an `accessibility check` line (controls with no
   name, touch targets under 48 dp / 44 pt), look at those controls on the screenshot. Report
   each kind once, with the screens where you saw it: minor, unless it stops a task.

## About this app: Hive Now (test build "Hive Staging")
Hive Now is a fashion and lifestyle marketplace in Kochi, India: clothes, sarees, kurtas,
footwear and beauty from local stores, delivered the same day. Prices are in rupees (₹). The app
is in English only; a phone set to another language is still a fair test of dates, prices and
layout. This build talks to a TEST backend: payments are Razorpay test mode and nothing is
delivered, so going all the way to payment is wanted.

- Location: when the app asks, allow location. Your GPS is set to Kochi. If it says Hive does not
  deliver there, open the location screen and search the pincode `682016`.
- Sign in (needed to check out): choose phone sign-in and type ONLY the test number in your
  persona (`phone`, without +91 if the field already shows it). The code is `123456`. These are
  fictional numbers; no SMS is sent. If that number is refused, report it as a blocker and stop
  trying to sign in.
- Payment: on Razorpay's sheet use the test card `4111 1111 1111 1111`, any future expiry
  (for example 12/30), CVV `123`, any name; on the bank page tap Success. If Razorpay offers UPI,
  use `success@razorpay`. Never type a real card or UPI id.
- Do NOT type any phone number other than your persona's test number, anywhere (sign-in,
  "notify me", wish requests, gift orders, addresses). For an address phone use your test number.
- Do NOT tap "Continue on WhatsApp", "Get the code on WhatsApp" or any WhatsApp, call or share
  button: they leave the app. Note that they exist; do not follow them.
- Out of scope: the seller app, the website, push notifications, account deletion.
- Hive-specific things worth checking: the delivery time and fee shown before paying match the
  bag and checkout; size selection and "out of stock" states; the bag when items come from two
  stores; prices are whole rupees and consistent between product, bag, review and order success;
  the order appears under Orders after paying.

## Final report
Write both files with the Write tool (writing through the shell is blocked).
1. `results/<persona>/report.md`
   - 5-line summary with the device.
   - Issues, most severe first. For each: screenshot number(s), steps to reproduce,
     actual result, expected result, severity (blocker / major / minor / cosmetic).
   - Device-specific layout problems (same format, shorter).
   - The persona's opinion in their own words: would they keep the app? score /10.
2. `results/<persona>/findings.json`:
   `{"score": 7, "issues": [{"title": "...", "severity": "major", "screen": "Sign-up", "screens": ["05", "06"]}]}`
