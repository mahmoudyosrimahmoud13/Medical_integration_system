# HealthHub AI: what we found and the plan

## The short version

- **The 2024 drug interaction model is not safe to show to patients as it was used.** It says "interaction" for about half of drug pairs that are actually safe, and the interaction name it gives back is never the right one.
- **The fix is already built:** HealthHub now answers from DrugBank's list of known interactions first (191,511 pairs, real descriptions). The old model is kept only as an optional second opinion for pairs DrugBank doesn't list. It runs with a strict threshold and never names a type.
- **The bone fracture model can't be reused.** Its model file was never added to the repo. It has to be trained again.

## What was in the 2024 repo

| Piece | Where | What it is |
|---|---|---|
| Drug interaction model | `machine` branch, `model/` | MVN-DDI, a graph neural network (published 2022). Each drug is read from its SMILES as a molecule graph. It scores 86 DrugBank interaction types. 1.7 million weights in `ddi.pkl` (6 MB). |
| Interaction API | `flask` branch, `Flask_api/app.py` | Flask, `POST /CheckInteraction` with two SMILES. Returns `InteractionResult` and `InteractionNameIndex`. The ASP.NET backend called it. |
| Bone fracture API | `flask` branch, `Flask_api/img_api.py` | Flask, `POST /predict` with an X-ray image. A Keras VGG16 model loaded from `F:/xray/model.pkl`. |
| Bone fracture model | `machine` branch, `bone_fraction` | A text file that says "detecting bone fraction". No model, no training code. |

## How I tested the interaction model

- The model loaded fine. It is MVN-DDI with 4 blocks, 55 atom features and 86 types, trained on the public DrugBank set (1,706 drugs, 191,808 known pairs).
- I used the same public data the model was trained on. It is published with the SSI-DDI paper at https://github.com/kanz76/SSI-DDI.
- I scored 400 known interactions from the test split and 400 random pairs DrugBank does not list. Then I scored 250 pairs from the training split, which the model has already seen.
- Anyone can run it again with `./run.sh evaluate <data folder>`.

## What we found

**1. It flags too many safe pairs.**
The old API said "interaction" if any of the 86 types scored above 0.5.

| Rule | Real interactions caught | Safe pairs wrongly flagged |
|---|---|---|
| Any type above 0.50 (2024 rule) | 94% | **54%** |
| Above 0.80 | 72% | 22% |
| Above 0.90 | 58% | 13% |
| Above 0.95 (new setting) | 43% | 5% |

- The overall ranking quality (AUROC) is 0.83. The model has a real signal, but it is not strong enough to be the main answer.

**2. The interaction name is always wrong.**
- The type the model picks matches DrugBank's type 0% of the time, even on pairs it was trained on.
- Most types collapse into a few outputs. For example, 72% of "type 25" pairs come out as "type 48".
- This means the labels used in training were numbered differently, and that numbering was lost. The names can't be recovered without training again.

**3. The 86 type numbers point to the rows of DrugBank's description file, in file order.**
- Earlier guesses (number + 1, text sort) gave nonsense like "sildenafil + nitroglycerin: hypersensitivity".
- Row order gives the right answers. Aspirin + warfarin: "may increase the anticoagulant activities". Sildenafil + nitroglycerin: "vasodilatory". Clarithromycin + simvastatin: "serum concentration increased". The new service uses this.

**4. Bugs in the 2024 code**
- It crashed on any drug with a single atom, for example lithium, because there are no bonds.
- It ran the model 86 separate times per pair instead of once.
- It only checked one drug order, but the model gives different scores when you swap the two drugs.
- The model path was hard-coded to `C:/Users/ItShop/...` and the X-ray model path to `F:/xray/...`.
- `ddi.pkl` was a full Python pickle. It only loads with the exact same library versions, and loading a pickle can run code.

## What is built now (in `AI/`)

- **`ddi_service`** is a small FastAPI service.
  - It looks the pair up in DrugBank's list first and answers with a full sentence, for example "Aspirin may increase the anticoagulant activities of Warfarin."
  - It uses the model only when `USE_MODEL=true` and only for pairs DrugBank doesn't list. Even then it only answers when the score is at least 0.95, as "possible interaction, check with a pharmacist", and never with a type name.
  - It keeps the 2024 `/CheckInteraction` contract, so old clients still work.
- **The model is ported** into one clean file (`ddi_service/mvn.py`).
  - The weights were converted to a plain weights file (`weights/mvn_ddi.pt`), so no pickle.
  - It works on current PyTorch Geometric (checked on 2.8.1). The scores are identical to the 2024 model.
  - The single-atom crash is fixed, and all 86 types are scored in one pass (about 0.3 s per pair for both drug orders on a 2-core CPU).
- **The backend** sends DrugBank ids, names and SMILES. It saves the description with each cached pair, so doctors see the sentence and not "type #45".
- **Docker:** the small image has no PyTorch. Build with `WITH_MODEL=1` to include the model.

## Plan from here

### Phase 1: use it (done)
- DrugBank lookup as the main answer, the model as an optional second opinion at 0.95.
- Show where the answer came from in the apps: "DrugBank" or "model estimate".

### Phase 2: train the interaction model again (about 1 to 2 weeks)
1. Train MVN-DDI from scratch on the public split. Save the label list next to the weights so type names can never be lost again.
2. Use proper negative pairs during training, then calibrate the scores (for example, Platt scaling on the validation split). Then 0.9 really means about 90%.
3. Report precision and recall per type on the test split. Only show type names that reach at least 80% precision.
4. Test on drugs the model has never seen (the "inductive" split). That is the real use case for new Egyptian products whose active ingredient isn't in the list.
5. Export to ONNX so the service can run without PyTorch, which takes the image from 3 GB to about 300 MB.

### Phase 3: Egyptian market coverage
- Link every brand in `egypt_products.csv` to its DrugBank ingredient (165 are done). The check then works when a doctor types "Panadol" or "Concor".
- Combination products (for example amoxicillin + clavulanic acid): check each ingredient.

### Phase 4: bone fracture (needs a new model)
- Use a public X-ray dataset. For example, FracAtlas (about 4,000 images with fracture labels and boxes) or MURA (Stanford, about 40,000 images, needs a sign-up).
- Train a small image model (EfficientNet or ResNet), and report sensitivity and specificity.
- Show it in the app only as "flag for the doctor to review", never as a diagnosis. Add it to the CT scan upload screen, and keep the doctor's own reading as the record.

## Things to keep in mind

- **Data license:** DrugBank's data is free for non-commercial use only. That's fine for a graduation project. Check DrugBank's terms before any commercial use. The data isn't stored in the repo; `./run.sh data` downloads it.
- **Not medical advice:** every interaction screen should say "check with a pharmacist or doctor". The model results, even at 0.95, are estimates.
