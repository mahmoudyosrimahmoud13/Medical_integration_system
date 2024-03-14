from flask import Flask, request, jsonify
from model.test_functions import check_interaction, get_interaction_name

app = Flask(__name__)

@app.route('/predict_interaction', methods=['POST'])
def predict_interaction():
    data = request.get_json()
    drug_1 = data.get('drug_1')
    drug_2 = data.get('drug_2')
    
    interaction_result = check_interaction(drug_1, drug_2)
    interaction_name_index = get_interaction_name(drug_1, drug_2)
    
    return jsonify({
        'interaction_result': interaction_result,
        'interaction_name_index': interaction_name_index
    })

if __name__ == '__main__':
    app.run(debug=True)
