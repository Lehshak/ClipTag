# ClipTag

An iOS app that looks at a short video and works out what's in it. Pick a clip and it pulls
out keyframes, tags them, finds where the scenes change, and suggests a frame that would make
a decent thumbnail. Everything runs on the phone and nothing gets uploaded.

[Demo](Cliptag.mov)

<img width="431" height="940" alt="Screenshot 2026-08-19 at 2 18 10 PM" src="https://github.com/user-attachments/assets/f0eef7e9-b51e-4214-afcb-6177360930d4" />


## What it does

- Samples about one frame per second out of the clip
- Runs Vision's image classifier on each frame to get labels
- Finds scene cuts by comparing consecutive frames
- Scores every frame for blur and picks a thumbnail
- Reports how long all of that took

<img width="431" height="941" alt="Screenshot 2026-08-19 at 2 17 41 PM" src="https://github.com/user-attachments/assets/9bc40c9a-614a-4888-b28c-fbc755771f0a" />


There's a Tuning tab for changing the sampling rate, cut sensitivity, how many frames get
processed at once, and the thumbnail scoring weights. Changing anything lets you re-run
against the clip you already imported instead of picking it again.

## How it works

No model files ship with the app. Vision already has an image classifier
VNClassifyImageRequest and an image embedding VNGenerateImageFeaturePrintRequest
built into iOS, so I used those.

Scene detection is just the distance between the embeddings of two consecutive frames. If it
jumps past a threshold, that's a cut. Blur detection is variance of the Laplacian on a small
grayscale copy of each frame, which is cheap and good enough to keep motion-blurred frames
from being picked as the thumbnail.

Frames are processed a few at a time in a task group instead of one after another. You can
set that to 1 in the Tuning tab to see what the difference actually is.

<img width="432" height="939" alt="Screenshot 2026-08-19 at 2 18 53 PM" src="https://github.com/user-attachments/assets/105a4601-f86c-4c77-aab5-ca300478caa8" />


Layout is simple. Services has the pipeline, ViewModels has the single
observable object holding state, Views has the three tabs.

## Numbers

On an iPhone [MODEL], a [N] second clip takes about [X] seconds, roughly [Y]ms per frame.
Setting concurrency to 1 puts it at [Z]ms per frame.

<img width="427" height="939" alt="Screenshot 2026-08-19 at 2 18 23 PM" src="https://github.com/user-attachments/assets/c039ad64-0e9c-4fb3-ba51-accb5a62e3b3" />

## Notes

Core ML fails to start on some simulator runtimes, which takes the classifier down with it.
The app notices and falls back to comparing colour histograms so scene detection still works,
but you won't get any tags. Use a real device.

The scene cut threshold is tuned by eye on my own clips, so it may need adjusting for
different footage. That's why it's a slider.

Requires iOS 26.1.

## Future

- Move frame preprocessing into a Metal shader and see if it's actually faster
- Export the tags and the chosen thumbnail

