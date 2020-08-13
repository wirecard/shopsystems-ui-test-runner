#!/bin/bash
set -e # Exit with nonzero exit code if anything fails
export WOOCOMMERCE_CONTAINER_NAME=woo_commerce

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

git clone https://"${GITHUB_TOKEN}":@github.com/wirecard-cee/docker-images.git

cd docker-images/woocommerce-ci

SHOP_VERSION=5.4.2 WIRECARD_PLUGIN_VERSION=${WIRECARD_PLUGIN_VERSION} PHP_VERSION=${PHP_VERSION} INSTALL_WIRECARD_PLUGIN=true ./run.xsh ${WOOCOMMERCE_CONTAINER_NAME} --daemon

docker ps

while ! $(curl --output /dev/null --silent --head --fail "${NGROK_URL}/wp-admin/install.php"); do
    echo "Waiting for docker container to initialize"
    sleep 5
    ((c++)) && ((c == 50)) && break
done

sleep 5

# change hostname
docker exec -i ${WOOCOMMERCE_CONTAINER_NAME} /opt/wirecard/apps/woocommerce/bin/hostname-changed.xsh "${NGROK_URL#*//}"

# make PayPal order number unique
docker exec -i ${WOOCOMMERCE_CONTAINER_NAME} bash -c "sed -i 's/ = \$this->orderNumber\;/ = \$this->orderNumber . md5(time())\;/' /srv/http/wp-content/plugins/woocommerce-wirecard-ee/vendor/wirecard/payment-sdk-php/src/Transaction/PayPalTransaction.php"
