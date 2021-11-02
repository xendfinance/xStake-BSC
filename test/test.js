const { expectRevert, time } = require('@openzeppelin/test-helpers');

const XendStaking = artifacts.require('XendStaking');
const MockXend = artifacts.require('AnyswapV4ERC20');

const PERIOD_SILVER = 30;
const PERIOD_GOLD = 60;

contract('XendStaking', async([alice, bob, dev, minter, admin]) => {

  beforeEach(async () => {
    this.xendStaking = await XendStaking.new({
      from: minter
    })

    this.mockXend = await MockXend.new(
      'XEND', 
      'XEND', 
      18, 
      '0x0000000000000000000000000000000000000000', 
      minter, 
      {
        from: minter
      }
    )

    await this.xendStaking.setContractAddress(this.mockXend.address, {
      from: minter
    })

    await this.mockXend.initVault(minter, {
      from: minter
    })

    await this.mockXend.mint(minter, web3.utils.toWei('10000'), {
      from: minter
    })

    await this.mockXend.transfer(alice, web3.utils.toWei('200'), {
      from: minter
    })

    await this.mockXend.approve(this.xendStaking.address, web3.utils.toWei('100'), {
      from: minter
    })
    
    await this.xendStaking.addTokenReward(web3.utils.toWei('100'), {
      from: minter
    })

    await this.xendStaking.addPackage(30, 15 * 24 * 3600, 565, 142, web3.utils.toWei('10000000000'), {
      from: minter
    })

    await this.xendStaking.addPackage(60, 30 * 24 * 3600, 1754, 504, web3.utils.toWei('10000000000'), {
      from: minter
    })

  })

  it("add package, set package", async () => {
    await this.xendStaking.setPackage(1, 60, 30 * 24 * 3600, 1754, 504, web3.utils.toWei('10000000000'), {
      from: minter
    })
  })

  it("deposit tokens, withdraw tokens", async () => {
    
    const xendBalance = web3.utils.toWei('100')

    console.log('balance before:', xendBalance.toString())
    
    await this.mockXend.approve(this.xendStaking.address, xendBalance, {
      from: alice
    })

    await this.xendStaking.stakeToken(xendBalance, PERIOD_SILVER, {
      from: alice
    })

    await time.increase(time.duration.days(30));

    await this.mockXend.approve(this.xendStaking.address, xendBalance, {
      from: alice
    })

    await this.xendStaking.stakeToken(xendBalance, PERIOD_GOLD, {
      from: alice
    })

    const stakingIds = await this.xendStaking.getTokenStakingIdByAddress(alice)

    // console.log('staking ids:', stakingIds)

    let userInfo = await this.xendStaking.getUserInfoByAddress(alice);
    console.log('staked:', userInfo.staked.toString());
    console.log('earned:', userInfo.earned.toString());
    console.log('reward:', userInfo.reward.toString());

    await time.increase(time.duration.days(30));

    userInfo = await this.xendStaking.getUserInfoByAddress(alice);
    console.log('staked:', userInfo.staked.toString());
    console.log('earned:', userInfo.earned.toString());
    console.log('reward:', userInfo.reward.toString());

    await this.xendStaking.withdrawStakedTokens(stakingIds[0], {
      from: alice
    })

    const xendBalanceAfter = await this.mockXend.balanceOf(alice)

    console.log('balance after:', xendBalanceAfter.toString())

  })
})