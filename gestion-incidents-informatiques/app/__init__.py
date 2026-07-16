from flask import Flask

from config import Config
from app import db as db_module


def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    db_module.init_app(app)

    # IMPORT BLUEPRINTS
    from app.auth import bp as auth_bp
    from app.incidents import bp as incidents_bp
    from app.admin import bp as admin_bp

    # REGISTER BLUEPRINTS
    app.register_blueprint(auth_bp)
    app.register_blueprint(incidents_bp)
    app.register_blueprint(admin_bp)

    @app.context_processor
    def inject_user():
        from flask import session
        return {
            "current_user_nom": session.get("nom"),
            "current_user_role": session.get("role"),
        }

    @app.route("/")
    def index():
        from flask import redirect, url_for, session
        if "id_utilisateur" in session:
            return redirect(url_for("incidents.dashboard"))
        return redirect(url_for("auth.login"))

    @app.route("/test")
    def test():
        return "Ca marche ! Flask est bien lance."

    return app
