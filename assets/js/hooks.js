let Hooks = {}

Hooks.DateTimeFmt = {
    mounted() {
        const timeStr = this.el.innerText;
        this.el.innerText = new Date(timeStr).toLocaleString();
    }
}

export default Hooks;
