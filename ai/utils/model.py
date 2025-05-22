# model.py
from sklearn.linear_model import SGDClassifier
import joblib

def train_incremental_model(X, y, classes):
    """
    Inițializează și antrenează un model SGDClassifier cu partial_fit.
    """
    clf = SGDClassifier(loss='log_loss', max_iter=1000, tol=1e-3, random_state=42)
    clf.partial_fit(X, y, classes=classes)
    return clf

def update_model(model, X_new, y_new):
    """
    Actualizează modelul incremental cu date noi.
    """
    model.partial_fit(X_new, y_new)
    return model

def save_model(model, path):
    """
    Salvează modelul pe disc.
    """
    joblib.dump(model, path)

def load_model(path):
    """
    Încarcă modelul salvat.
    """
    return joblib.load(path)
