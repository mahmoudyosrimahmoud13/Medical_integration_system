
# Drug Interaction Predictor

This project helps predict potential interactions between pairs of drugs using a machine learning model. You can use the model from the console.


### Using the Model via Console:

1. Ensure you have Python installed on your machine and you have required dependencies

2. from model file open test_model.py  .

3. Run the script

5. Follow the prompts:

    - Enter the number of interactions you want to check.
    - For each interaction, enter the SMILES representations of the two drugs and .
    - The script will print `1` if an interaction is detected between the provided drug pairs and `0` otherwise.

## Input Format

when  using the model, provide the drug pairs as SMILES representations.

## Output Format

 you will find two functions which you will pass two drugs smiles and will return the interaction name or the interacion boolean vlalue as you want
 ## 1-def check_interaction(drug_1,drug_2):
 which will return 0 if there is not interaction and 1 if there is interaction between two drugs
 ## 2- get_interaction_name (drug_1,drug_2):
 which will retun the interaction name index if there is interaction and if there is not interaction will return None value
 

 
 



