from functools import wraps

from flask import session, redirect, url_for, flash, abort


def login_required(view):
    @wraps(view)
    def wrapped(*args, **kwargs):
        if "id_utilisateur" not in session:
            flash("Merci de vous connecter.", "warning")
            return redirect(url_for("auth.login"))
        return view(*args, **kwargs)
    return wrapped


def roles_required(*roles_autorises):
    def decorator(view):
        @wraps(view)
        def wrapped(*args, **kwargs):
            if session.get("role") not in roles_autorises:
                abort(403)
            return view(*args, **kwargs)
        return wrapped
    return decorator