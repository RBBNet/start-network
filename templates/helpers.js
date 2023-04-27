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

    Handlebars.registerHelper('uid', function() {
      return process.getuid();
    });

    Handlebars.registerHelper("select", function(...keys) {
      const _options = keys.pop();
      const items = keys.pop();

      return items.map((item) =>
        Object.fromEntries(keys.map((key) => [key, item[key]]))
      );
    });

    Handlebars.registerHelper("enode", function(nodes) {
      let result;
      if (nodes instanceof Array) {
        result = nodes.map(({ publicKey, address }) => `enode://${publicKey.slice(2)}@${address}`);
      } else if ('publicKey' in nodes) {
        const { publicKey, address } = nodes;
        result = `enode://${publicKey.slice(2)}@${address}`;
      } else {
        result = Object.values(nodes).map(({ publicKey, address }) => `enode://${publicKey.slice(2)}@${address}`);
      }
      return result;
    });

    Handlebars.registerHelper('tcp', function(address) {
      if (!address) return;
      const { hostname, port } = new URL(`http://${address}`);
      return { host: hostname, port };
    });

    Handlebars.registerHelper("pluck", function(key, items) {
      if (items instanceof Array) {
        return items.map((item) => item[key]);
      } else {
        return Object.values(items).map((item) => item[key]);
      }
    });

    Handlebars.registerHelper("where", function(list, options) {
      let result;
      if (!(list instanceof Array)) {
        list = Object.entries(list);
        result = list.filter(([_, item]) =>
          Object.entries(options.hash).every(([key, value]) => item[key] == value)
        );
        result = Object.fromEntries(result);
      } else {
        result = list.filter((item) =>
          Object.entries(options.hash).every(([key, value]) => item[key] == value)
        );
      }
      return result;
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
