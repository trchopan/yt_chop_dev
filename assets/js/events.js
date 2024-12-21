window.addEventListener('phx:reset-recaptcha', e => {
    e.preventDefault();
    window.grecaptcha.enterprise.reset();
});
