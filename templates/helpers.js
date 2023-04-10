const { execSync } = require("child_process");

function besuRlpEncode(type, validators) {
  return execSync(`besu rlp encode --type=${type}_EXTRA_DATA`, {
    env: {
      ...process.env,
      LOG4J_CONFIGURATION_FILE: "/var/lib/besu/logging-off.xml",
    },
    input: JSON.stringify(validators),
  }).toString().split("\n").shift();
}

module.exports = {
  register: (Handlebars) => {
    Handlebars.registerHelper(
      "rlpEncode",
      function(validatorsOrOptions, options) {
        let validators = validatorsOrOptions;
        if (!options) {
          options = validatorsOrOptions;
          validators = options.hash.validators;
        }
        const { type } = options.hash;
        const extraData = besuRlpEncode(type, validators);

        return extraData;
      },
    );

    Handlebars.registerHelper("select", function(...keys) {
      const _options = keys.pop();
      const items = keys.pop();

      return items.map((item) =>
        Object.fromEntries(keys.map((key) => [key, item[key]]))
      );
    });

    Handlebars.registerHelper("enode", function(nodes) {
      if (!(nodes instanceof Array)) {
        nodes = [nodes];
      }
      return nodes.map(({ publicKey, address }) =>
        `enode://${publicKey.slice(2)}@${address}`
      );
    });

    Handlebars.registerHelper("pluck", function(key, items) {
      return items.map((item) => item[key]);
    });

    Handlebars.registerHelper("where", function(list, options) {
      if (!(list instanceof Array)) {
        list = Object.values(list);
      }

      return list.filter((item) =>
        Object.entries(options.hash).every(([key, value]) => item[key] == value)
      );
    });

    Handlebars.registerHelper("json", function(x) {
      return new Handlebars.SafeString(JSON.stringify(x));
    });

    Handlebars.registerHelper("hex", function(x) {
      return `0x${x.toString(16)}`;
    });

    Handlebars.registerHelper("now", function() {
      return parseInt((Date.now() / 1000).toFixed(0));
    });

    Handlebars.registerHelper("env", function(key) {
      return process.env[key];
    });

    Handlebars.registerHelper("fallback", function(...values) {
      const _options = values.pop();
      return values.find((v) => typeof v !== "undefined");
    });
  },
};
