let Hooks = {};

Hooks.DateTimeFmt = {
    mounted() {
        const timeStr = this.el.innerText;
        this.el.innerText = new Date(timeStr).toLocaleString();
    },
};

Hooks.Recaptcha = {
    mounted() {
        window.grecaptcha.enterprise.ready(() => {
            window.grecaptcha.enterprise.render(this.el, {
                sitekey: this.el.dataset.sitekey,
                action: this.el.dataset.action,
            });
        });
    },
};

export default Hooks;
