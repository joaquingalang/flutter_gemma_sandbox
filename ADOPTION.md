# Flutter Gemma Chat — Adoption Checklist

## Context

This guide documents everything needed to replicate the `flutter_gemma_sandbox` chat setup in a fresh Flutter project. The setup provides a full on-device LLM chat experience using Google's Gemma 4 model via the `flutter_gemma` package, with support for text, image, and audio inputs, streaming responses, and markdown rendering. `ChatPage` accepts a `systemInstruction` parameter so callers can customize the assistant's behavior per use case.

---

## 1. pubspec.yaml — Add Dependencies

- [ ] Add `flutter_gemma: ^0.13.2`
- [ ] Add `sizer: ^3.1.3`
- [ ] Add `flutter_dotenv: ^6.0.0`
- [ ] Add `flutter_markdown_plus: ^1.0.7`
- [ ] Add `image_picker: ^1.1.2`
- [ ] Add `record: ^6.2.0`
- [ ] Add `path_provider: ^2.1.5`
- [ ] Register `assets/` directory under the `flutter > assets:` section
- [ ] Run `flutter pub get`

---

## 2. Assets — Environment File

- [ ] Create `assets/` directory at project root
- [ ] Create `assets/.env` with content:
  ```
  HF_TOKEN=your_huggingface_token_here
  ```
- [ ] Ensure `assets/` is listed in `pubspec.yaml` (covered above)

---

## 3. Android Permissions — AndroidManifest.xml

File: `android/app/src/main/AndroidManifest.xml`

Add the following `<uses-permission>` tags **before** the `<application>` tag:

- [ ] `<uses-permission android:name="android.permission.INTERNET" />` — model download
- [ ] `<uses-permission android:name="android.permission.RECORD_AUDIO" />` — audio input
- [ ] `<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />` — gallery access (Android 13+)
- [ ] `<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />` — gallery fallback (Android ≤12)

Optionally, inside `<application>`, add native OpenCL libraries for GPU acceleration:

- [ ] (Optional) Add `<uses-native-library android:name="libOpenCL.so" android:required="false" />`
- [ ] (Optional) Add `<uses-native-library android:name="libOpenCL-car.so" android:required="false" />` (Qualcomm Adreno)
- [ ] (Optional) Add `<uses-native-library android:name="libOpenCL-pixel.so" android:required="false" />` (Google Tensor)

---

## 4. Enums

### `lib/enums/sender.dart`
- [ ] Create `Sender` enum with values: `user`, `gemma`

---

## 5. Components

### `lib/components/chat_bubble.dart`
- [ ] Create `ChatBubble extends StatelessWidget`
- [ ] Constructor params: `content: String`, `sender: Sender`, `imageBytes: Uint8List?`, `hasAudio: bool` (default `false`)
- [ ] Border radius: 12pt with flat bottom corner on the sender's side
- [ ] Max width: 60% of screen (`sizer` package: `60.w`)
- [ ] Margin: 12px left/right, 16px bottom; padding: 8px all
- [ ] Render image (if `imageBytes != null`) via `ClipRRect` above the text
- [ ] Render audio chip (if `hasAudio == true`) with icon + "Audio" label
- [ ] Render Gemma text via `MarkdownBody` (`flutter_markdown_plus`) with stylesheet: body 16pt, code 14pt with gray background
- [ ] Render user text via plain `Text` widget (16pt)

---

## 6. Widgets

### `lib/widgets/stage_views.dart`
- [ ] Create `DownloadingView extends StatelessWidget`
  - [ ] Param: `progress: int`
  - [ ] Shows "Downloading model" label, `LinearProgressIndicator`, percentage text
- [ ] Create `LoadingView extends StatelessWidget`
  - [ ] Shows "Loading model into memory…" with `CircularProgressIndicator`
- [ ] Create `ErrorView extends StatelessWidget`
  - [ ] Params: `error: String`, `onRetry: VoidCallback`
  - [ ] Shows error icon, message text, error details, and a retry button

### `lib/widgets/chat_view.dart`
- [ ] Create `ChatView extends StatelessWidget`
- [ ] Constructor params:
  - `logs: List<ChatBubble>`
  - `isGenerating: bool`
  - `streamingBuffer: String`
  - `messageController: TextEditingController`
  - `pendingImageBytes: Uint8List?`
  - `pendingAudioBytes: Uint8List?`
  - `isRecording: bool`
  - `onSend: VoidCallback`
  - `onPickImage: VoidCallback`
  - `onClearImage: VoidCallback`
  - `onStartRecord: VoidCallback`
  - `onStopRecord: VoidCallback`
  - `onClearAudio: VoidCallback`
- [ ] Layout is a `Column` with three zones:
  1. **Message list** (`Expanded`): reversed `ListView` of `ChatBubble` widgets; if `isGenerating`, prepend a streaming preview bubble
  2. **Media previews**: image thumbnail (64×64) with cancel button if `pendingImageBytes != null`; "Audio recorded" chip with cancel if `pendingAudioBytes != null`
  3. **Input bar** (fixed height ~80): image-picker icon, mic icon (red when `isRecording`), `TextField`, send button — all disabled while `isGenerating` or `isRecording`

---

## 7. ChatPage

### `lib/pages/chat_page.dart`
- [ ] Create `ChatPage extends StatefulWidget`
- [ ] **Constructor param:** `systemInstruction: String` (required, passed through to `createChat`)
- [ ] State class: `_ChatPageState`
- [ ] Stage enum (private): `_Stage { downloading, loading, ready, error }`
- [ ] Instance variables:
  - `_stage: _Stage`
  - `_downloadProgress: int`
  - `_error: String?`
  - `_chat: InferenceChat?`
  - `_isGenerating: bool`
  - `_streamingBuffer: String`
  - `_pendingImageBytes: Uint8List?`
  - `_pendingAudioBytes: Uint8List?`
  - `_isRecording: bool`
  - `_recorder: AudioRecorder`
  - `_messageController: TextEditingController`
  - `_logs: List<ChatBubble>`
- [ ] Call `_bootstrap()` from `initState()`
- [ ] Implement `_bootstrap()`:
  - [ ] Load `assets/.env` via `dotenv.load`
  - [ ] Check `FlutterGemma.hasActiveModel()`; skip download if true
  - [ ] Download model via `FlutterGemma.installModel(...).fromNetwork(...).withProgress(...).install()`
    - Model URL: `https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm`
    - `modelType: ModelType.gemmaIt`, `fileType: ModelFileType.litertlm`
  - [ ] Load model: `FlutterGemma.getActiveModel(maxTokens: 2048, preferredBackend: PreferredBackend.gpu, supportImage: true, supportAudio: true)`
  - [ ] Create chat: `model.createChat(supportImage: true, supportAudio: true, systemInstruction: widget.systemInstruction)`
  - [ ] Set `_stage = _Stage.ready` on success; set `_stage = _Stage.error` and `_error` on failure
- [ ] Implement `_pickImage()` using `ImagePicker().pickImage(source: ImageSource.gallery)`, store bytes in `_pendingImageBytes`
- [ ] Implement `_startRecording()`: check permission, get temp dir, start WAV recording (16kHz mono)
- [ ] Implement `_stopRecording()`: stop recorder, read file bytes into `_pendingAudioBytes`
- [ ] Implement `_sendUserMessage()`:
  - [ ] Guard: not generating, chat not null, content or media present
  - [ ] Construct `Message` using the correct factory (`withImage`, `withAudio`, `audioOnly`, or `text`)
  - [ ] Call `_chat!.addQueryChunk(message)`
  - [ ] Stream `_chat!.generateChatResponseAsync()`, accumulate tokens in `_streamingBuffer`
  - [ ] On stream complete: add `ChatBubble` to `_logs`, clear buffer, set `_isGenerating = false`
  - [ ] On stream error: add error `ChatBubble`
- [ ] Override `dispose()`: dispose `_recorder` and `_messageController`
- [ ] Build method returns `Scaffold` with `AppBar` and a `switch` on `_stage`:
  - `downloading` → `DownloadingView(progress: _downloadProgress)`
  - `loading` → `LoadingView()`
  - `error` → `ErrorView(error: _error!, onRetry: _bootstrap)`
  - `ready` → `ChatView(...)` with all state and callbacks wired up

---

## 8. main.dart

- [ ] Add `WidgetsFlutterBinding.ensureInitialized()`
- [ ] Load env: `await dotenv.load(fileName: 'assets/.env')`
- [ ] Initialize Gemma: `await FlutterGemma.initialize(huggingFaceToken: dotenv.env['HF_TOKEN']!)`
- [ ] Wrap root widget in `Sizer` builder (from `sizer` package)
- [ ] Pass `systemInstruction` when constructing `ChatPage`, e.g.:
  ```dart
  home: ChatPage(systemInstruction: 'You are a helpful assistant. Be concise and clear.')
  ```

---

## 9. Verification

- [ ] Run `flutter pub get` — no resolution errors
- [ ] Run `flutter analyze` — no critical lint errors
- [ ] Build and install on an Android device (API 26+)
- [ ] First launch: confirm model download progress bar appears and completes
- [ ] Second launch: confirm model loads immediately (no re-download)
- [ ] Send a text message — confirm streamed response appears token-by-token, then settles as a markdown bubble
- [ ] Pick an image from gallery — confirm thumbnail preview, send with text, confirm image shown in chat bubble
- [ ] Record audio — confirm mic turns red, stop recording, send, confirm audio chip in chat bubble
- [ ] Verify `systemInstruction` shapes the assistant persona (e.g., pass a different instruction and observe changed behavior)
- [ ] Rotate device / change font size — confirm `sizer`-based layout remains readable
