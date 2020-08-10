#!/bin/bash
set -e # Exit with nonzero exit code if anything fails
export WOOCOMMERCE_CONTAINER_NAME=woo_commerce
export WOOCOMMERCE_PATH="shopsystems-ui-test-runner/woocommerce-ee"

for ARGUMENT in "$@"; do
  KEY=$(echo "${ARGUMENT}" | cut -f1 -d=)
  VALUE=$(echo "${ARGUMENT}" | cut -f2 -d=)

  case "${KEY}" in
  NGROK_URL) NGROK_URL=${VALUE} ;;
  SHOP_VERSION) SHOP_SYSTEM_VERSION=${VALUE} ;;
  PHP_VERSION) PHP_VERSION=${VALUE} ;;
  USE_SPECIFIC_EXTENSION_RELEASE) USE_SPECIFIC_EXTENSION_RELEASE=${VALUE} ;;
  SPECIFIC_RELEASED_SHOP_EXTENSION_VERSION) SPECIFIC_RELEASED_SHOP_EXTENSION_VERSION=${VALUE} ;;
  *) ;;
  esac
done

if [[ ${USE_SPECIFIC_EXTENSION_RELEASE}  == "1" ]]; then
  git checkout tags/"${SPECIFIC_RELEASED_SHOP_EXTENSION_VERSION}"
fi

${WOOCOMMERCE_PATH}/generate-release-package.sh

export WOOCOMMERCE_ADMIN_USER=admin
export WOOCOMMERCE_ADMIN_PASSWORD=password

git clone https://"${GITHUB_TOKEN}":@github.com/wirecard-cee/docker-images.git
cd docker-images/woocommerce-ci

./run.xsh ${WOOCOMMERCE_CONTAINER_NAME} --daemon

while ! $(curl --output /dev/null --silent --head --fail "${NGROK_URL}/wp-admin/install.php"); do
    echo "Waiting for docker container to initialize"
    sleep 5
    ((c++)) && ((c == 50)) && break
done

#install wordpress
docker exec -T web wp core install --allow-root --url="${NGROK_URL}" --admin_password="${WOOCOMMERCE_ADMIN_PASSWORD}" --title=test --admin_user=${WOOCOMMERCE_ADMIN_USER} --admin_email=test@test.com

#activate woocommerce
docker exec -T web wp plugin activate woocommerce --allow-root

#activate woocommerce-ee
docker exec -T web wp plugin activate wirecard-woocommerce-extension --allow-root

#install wordpress-importer
docker exec -T web wp plugin install wordpress-importer --activate --allow-root

#import sample product
docker exec -T web wp import /var/www/html/wp-content/plugins/woocommerce/sample-data/sample_products.xml --allow-root --authors=create

#activate storefront theme
docker exec -T web wp theme install storefront --activate --allow-root

#install shop pages
docker exec -T web wp wc tool run install_pages --user=admin --allow-root

#make PayPal order number unique
docker exec -T web bash -c "sed -i 's/ = \$this->orderNumber\;/ = \$this->orderNumber . md5(time())\;/' /var/www/html/wp-content/plugins/wirecard-woocommerce-extension/vendor/wirecard/payment-sdk-php/src/Transaction/PayPalTransaction.php"
